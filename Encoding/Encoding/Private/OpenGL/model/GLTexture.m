

#import "GLTexture.h"
#import "RectangleF.h"
#import "CC3GLMatrix.h"
#import "GLUtils.h"
#import "GLColor.h"

static NSString *TAG = @"GLTexture";

static const float coords[] = {
        0, 1, 0,   // top left
        0, 0, 0,   // bottom left
        1, 0, 0,   // bottom right
        1, 1, 0};  // top right
static const int COORDS_PER_VERTEX = 3;
static const int COORDS_LENGTH = COORDS_PER_VERTEX * 4;

static const GLubyte drawOrder[] = {
        0, 1, 2, // first triangle : top left, bottom left, bottom right
        0, 2, 3 // second triangle : top left, bottom right, top right
};
static const int DRAW_ORDER_LENGTH = 6;

static const float textureCoords[] = {
        0.f, 0.f,   // top left
        0.f, 1.f,   // bottom left
        1.f, 1.f,   // bottom right
        1.f, 0.f};  // top right

static const float invertedTextureCoords[] = {
        0.f, 1.f,   // top left
        0.f, 0.f,   // bottom left
        1.f, 0.f,   // bottom right
        1.f, 1.f};  // top right

static const int TEXTURE_COORDS_PER_VERTEX = 2;

@interface GLTexture () {
    GLuint vertexBuffer, indexBuffer, textureCoordsBuffer;
    float _color[4];
}

@property(nonatomic, strong) GLColor *glColor;
@property(nonatomic, strong) RectangleF *rectangle;
@property(nonatomic, assign) GLint glTexture;
@property(nonatomic, assign) BOOL inverted;

@property(nonatomic, assign) GLuint vertexShader, fragmentShader, program;
@property(nonatomic, assign) GLuint coordsHandle, texCoordsHandle, mVPMatrixHandle, texHandle, colorHandle;
@property(nonatomic, strong) CC3GLMatrix *modelMatrix;

@end

@implementation GLTexture {

}

- (instancetype)initWithRectangle:(RectangleF *)rectangle
                            color:(GLColor *)glColor
                        glTexture:(GLint)glTexture
                         inverted:(BOOL)inverted {
    self.rectangle = rectangle;
    self.glTexture = glTexture;
    self.inverted = inverted;
    self.glColor = glColor;
    [glColor setColorToArray:_color];

    [self prepare];

    return self;
}

+ (instancetype)textureWithRectangle:(RectangleF *)rectangle
                               color:(GLColor *)glColor
                           glTexture:(GLuint)glTexture
                            inverted:(BOOL)inverted {
    GLTexture *texture = [[GLTexture alloc] initWithRectangle:rectangle
                                                        color:glColor
                                                    glTexture:glTexture
                                                     inverted:inverted];
    return texture;
}

- (void)setX:(float)x {
    [self.rectangle setX:x];
    [self refreshModelMatrix];
}

- (void)draw:(float[])mVPMatrix {
    //glBindBuffer(GL_ARRAY_BUFFER, 0); // this if no VBOs
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); // this if no VBOs

    glUseProgram(self.program);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);

    // Position
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    //glVertexAttribPointer(self.coordsHandle, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), coords); // this if no VBOs
    glVertexAttribPointer(self.coordsHandle, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), 0);
    glEnableVertexAttribArray(self.coordsHandle);

    // Texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, (GLuint) self.glTexture);
    glUniform1i(self.texHandle, 0);

    // Texture Coords
    glBindBuffer(GL_ARRAY_BUFFER, textureCoordsBuffer);
    //glVertexAttribPointer(self.texCoordsHandle, TEXTURE_COORDS_PER_VERTEX, GL_FLOAT, GL_FALSE, 2*sizeof(float), textureCoords); // this if no VBOs
    glVertexAttribPointer(self.texCoordsHandle, TEXTURE_COORDS_PER_VERTEX, GL_FLOAT, GL_FALSE, 2 * sizeof(float), 0);
    glEnableVertexAttribArray(self.texCoordsHandle);

    // Matrix
    CC3GLMatrix *scaledMVPMatrix = [CC3GLMatrix multiplyMat:mVPMatrix
                                                   byMatrix:self.modelMatrix.glMatrix];

    glUniformMatrix4fv(self.mVPMatrixHandle, 1, GL_FALSE, scaledMVPMatrix.glMatrix);

    glUniform4fv(self.colorHandle, 1, _color);

    //glDrawElements(GL_TRIANGLES, DRAW_ORDER_LENGTH, GL_UNSIGNED_BYTE, drawOrder); // this if no VBOs
    glDrawElements(GL_TRIANGLES, DRAW_ORDER_LENGTH, GL_UNSIGNED_BYTE, 0);

    glDisableVertexAttribArray(self.texCoordsHandle);
    glDisableVertexAttribArray(self.coordsHandle);

    [GLUtils checkGLError:@"GLTexture draw"];
}

- (void)setColor:(GLColor *)glColor {
    self.glColor = glColor;
    [glColor setColorToArray:_color];
}

- (void)free {
    [GLUtils releaseProgram:self.program vertexShader:self.vertexShader fragmentShader:self.fragmentShader];
    [GLUtils checkGLError:@"GLTexture free"];
    //glDeleteTextures(1, &self.glTexture);
}

- (void)prepare {
    if (self.glTexture < 0)
        @throw [NSException exceptionWithName:TAG
                                       reason:@"No texture"
                                     userInfo:nil];

    [self setupMatrix];
    [self setupShaders];
    [self setupVBOs];
}

- (void)setupMatrix {
    self.modelMatrix = [CC3GLMatrix matrix];
    [self refreshModelMatrix];
}

- (void)refreshModelMatrix {
    [self.modelMatrix populateIdentity];
    [self.modelMatrix translateBy:CC3VectorMake(self.rectangle.x, self.rectangle.y, 0)];
    [self.modelMatrix scaleBy:CC3VectorMake(self.rectangle.w, self.rectangle.h, 0)];
}

- (void)setupShaders {
    [self compileShaders];
    [self setupShaderParams];
}

- (void)compileShaders {
    self.vertexShader = [GLUtils compileShader:@"texture_vertex" withType:GL_VERTEX_SHADER];
    self.fragmentShader = [GLUtils compileShader:@"texture_fragment" withType:GL_FRAGMENT_SHADER];
    self.program = [GLUtils compileProgram:self.vertexShader fragmentShader:self.fragmentShader];
    [GLUtils checkGLError:@"GLTexture setupShaders"];
}

- (void)setupShaderParams {
    // vertex
    self.coordsHandle = (GLuint) glGetAttribLocation(_program, "vPosition");
    self.texCoordsHandle = (GLuint) glGetAttribLocation(_program, "a_TexCoordinate");
    self.mVPMatrixHandle = (GLuint) glGetUniformLocation(_program, "uMVPMatrix");

    // fragment
    self.colorHandle = (GLuint) glGetUniformLocation(_program, "v_Color");
    self.texHandle = (GLuint) glGetAttribLocation(_program, "u_Texture");

    [GLUtils checkGLError:@"Font setupShaders"];
}

- (void)setupVBOs {
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(coords), coords, GL_STATIC_DRAW);

    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(drawOrder), drawOrder, GL_STATIC_DRAW);
    [GLUtils checkGLError:@"GLRectangle setupVBOs"];

    glGenBuffers(1, &textureCoordsBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, textureCoordsBuffer);
    if (self.inverted)
        glBufferData(GL_ARRAY_BUFFER, sizeof(invertedTextureCoords), invertedTextureCoords, GL_STATIC_DRAW);
    else
        glBufferData(GL_ARRAY_BUFFER, sizeof(textureCoords), textureCoords, GL_STATIC_DRAW);
}

@end
