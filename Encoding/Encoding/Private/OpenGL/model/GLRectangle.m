

#import "GLRectangle.h"
#import "RectangleF.h"
#import "GLColor.h"
#include <OpenGLES/ES2/gl.h>
#import "CC3GLMatrix.h"
#import "GLUtils.h"

static const float coords[] = {
        -0.5, 0.5, -0.5,   // top left
        -0.5, -0.5, -0.5,   // bottom left
        0.5, -0.5, -0.5,   // bottom right
        0.5, 0.5, -0.5};  // top right

static const int COORDS_PER_VERTEX = 3;
static const int VERTEX_STRIDE = COORDS_PER_VERTEX * 4;

static const GLubyte drawOrder[] = {
        0, 1, 2,
        2, 3, 0
};

static const int DRAW_ORDER_LENGTH = 6;

@interface GLRectangle () {
    float color[4];
    GLuint vertexBuffer, indexBuffer;
}

@property (nonatomic, strong) RectangleF *rectangle;

@property (nonatomic, assign)GLuint vertexShader, fragmentShader, program;
@property (nonatomic, assign)GLuint positionHandle, colorHandle, mVPMatrixHandle;
@property (nonatomic, strong) CC3GLMatrix *modelMatrix;

@end

@implementation GLRectangle {

}

- (instancetype)initWithRectangle:(RectangleF *)rectangle color:(GLColor *)glColor {
    self.rectangle = rectangle;
    
    [glColor setColorToArray:color];
    
    self.modelMatrix = [CC3GLMatrix matrix];

    [self refreshModelMatrix];
    [self initShaders];
    [self setupVBOs];

    return self;
}

- (void)draw:(float[])mvpMatrix {

    glUseProgram(self.program);

    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);

    // POSITION
    self.positionHandle = (GLuint)glGetAttribLocation(self.program, "vPosition");
    glEnableVertexAttribArray(self.positionHandle);

    glVertexAttribPointer(self.positionHandle, COORDS_PER_VERTEX, GL_FLOAT, GL_FALSE, VERTEX_STRIDE, 0);

    // COLOR
    self.colorHandle = (GLuint)glGetUniformLocation(self.program, "vColor");
    glUniform4fv(self.colorHandle, 1, color);

    // MATRIX
    self.mVPMatrixHandle = (GLuint)glGetUniformLocation(self.program, "uMVPMatrix");
    
    CC3GLMatrix *scaledMVPMatrix = [CC3GLMatrix multiplyMat:mvpMatrix byMatrix:self.modelMatrix.glMatrix];
    glUniformMatrix4fv(self.mVPMatrixHandle, 1, GL_FALSE, scaledMVPMatrix.glMatrix);

    glDrawElements(GL_TRIANGLES, DRAW_ORDER_LENGTH, GL_UNSIGNED_BYTE, 0);

    glDisableVertexAttribArray(self.positionHandle);
    [GLUtils checkGLError:@"GLRectangle draw"];
}

- (void)setColor:(GLColor *)glColor {
    [glColor setColorToArray:color];
}

- (void)free {
    [GLUtils releaseProgram:self.program vertexShader:self.vertexShader fragmentShader:self.fragmentShader];
    [GLUtils checkGLError:@"GLRectangle free"];
    //delete color;
}

- (void)setX:(float)x {
    [self.rectangle setX:x];
    [self refreshModelMatrix];
}

- (void)refreshModelMatrix {
    [self.modelMatrix populateIdentity];
    [self.modelMatrix translateBy:CC3VectorMake(self.rectangle.x, self.rectangle.y, 0)];
    [self.modelMatrix scaleBy:CC3VectorMake(self.rectangle.w, self.rectangle.h, 0)];
}

- (void)initShaders {
    self.vertexShader = [GLUtils compileShader:@"rectangle_vertex" withType:GL_VERTEX_SHADER];
    self.fragmentShader = [GLUtils compileShader:@"rectangle_fragment" withType:GL_FRAGMENT_SHADER];
    self.program = [GLUtils compileProgram:self.vertexShader fragmentShader:self.fragmentShader];
    [GLUtils checkGLError:@"GLRectangle init shaders"];
}

- (void)setupVBOs {
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(coords), coords, GL_STATIC_DRAW);

    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(drawOrder), drawOrder, GL_STATIC_DRAW);
    [GLUtils checkGLError:@"GLRectangle setupVBOs"];
}

- (void)rotateZ:(float)degrees {
    [self.modelMatrix rotateByZ:degrees];
}


@end
