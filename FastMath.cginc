#ifndef FASTMATH
#define FASTMATH

#define IEEE_INT_RCP_CONST_NR0              0x7EF311C2 
#define IEEE_INT_RCP_CONST_NR1              0x7EF311C3 
#define IEEE_INT_RCP_CONST_NR2              0x7EF312AC  

// Derived from batch testing
#define IEEE_INT_SQRT_CONST_NR0             0x1FBD1DF5   

// Biases for global ranges
// 0-1 or 1-2 specific ranges might improve from different bias
// Derived from batch testing
// TODO : Should be improved
#define IEEE_INT_RCP_SQRT_CONST_NR0         0x5f3759df
#define IEEE_INT_RCP_SQRT_CONST_NR1         0x5F375A86 
#define IEEE_INT_RCP_SQRT_CONST_NR2         0x5F375A86  

//
// Normalized range [0,1] Constants
//
#define IEEE_INT_RCP_CONST_NR0_SNORM        0x7EEF370B
#define IEEE_INT_SQRT_CONST_NR0_SNORM       0x1FBD1DF5
#define IEEE_INT_RCP_SQRT_CONST_NR0_SNORM   0x5F341A43

// Approximate guess using integer float arithmetics based on IEEE floating point standard
float rcpSqrtIEEEIntApproximation(float inX, const int inRcpSqrtConst)
{
	int x = asint(inX);
	x = inRcpSqrtConst - (x >> 1);
	return asfloat(x);
}

float rcpSqrtNewtonRaphson(float inXHalf, float inRcpX)
{
	return inRcpX * (-inXHalf * (inRcpX * inRcpX) + 1.5f);
}

//
// Using 0 Newton Raphson iterations
// Relative error : ~3.4% over full
// Precise format : ~small float
// 2 ALU
//
float fastRcpSqrtNR0(float inX)
{
	float  xRcpSqrt = rcpSqrtIEEEIntApproximation(inX, IEEE_INT_RCP_SQRT_CONST_NR0);
	return xRcpSqrt;
}

//
// Using 1 Newton Raphson iterations
// Relative error : ~0.2% over full
// Precise format : ~half float
// 6 ALU
//
float fastRcpSqrtNR1(float inX)
{
	float  xhalf = 0.5f * inX;
	float  xRcpSqrt = rcpSqrtIEEEIntApproximation(inX, IEEE_INT_RCP_SQRT_CONST_NR1);
	xRcpSqrt = rcpSqrtNewtonRaphson(xhalf, xRcpSqrt);
	return xRcpSqrt;
}

//
// Using 2 Newton Raphson iterations
// Relative error : ~4.6e-004%  over full
// Precise format : ~full float
// 9 ALU
//
float fastRcpSqrtNR2(float inX)
{
	float  xhalf = 0.5f * inX;
	float  xRcpSqrt = rcpSqrtIEEEIntApproximation(inX, IEEE_INT_RCP_SQRT_CONST_NR2);
	xRcpSqrt = rcpSqrtNewtonRaphson(xhalf, xRcpSqrt);
	xRcpSqrt = rcpSqrtNewtonRaphson(xhalf, xRcpSqrt);
	return xRcpSqrt;
}


//
// SQRT
//
float sqrtIEEEIntApproximation(float inX, const int inSqrtConst)
{
	int x = asint(inX);
	x = inSqrtConst + (x >> 1);
	return asfloat(x);
}

//
// Using 0 Newton Raphson iterations
// Relative error : < 0.7% over full
// Precise format : ~small float
// 1 ALU
//
float fastSqrtNR0(float inX)
{
    inX += 0.0430;
	float  xRcp = sqrtIEEEIntApproximation(inX, IEEE_INT_SQRT_CONST_NR0);
	return xRcp;
}

//
// Use inverse Rcp Sqrt
// Using 1 Newton Raphson iterations
// Relative error : ~0.2% over full
// Precise format : ~half float
// 6 ALU
//
float fastSqrtNR1(float inX)
{
	// Inverse Rcp Sqrt
	return inX * fastRcpSqrtNR1(inX);
}

//
// Use inverse Rcp Sqrt
// Using 2 Newton Raphson iterations
// Relative error : ~4.6e-004%  over full
// Precise format : ~full float
// 9 ALU
//
float fastSqrtNR2(float inX)
{
	// Inverse Rcp Sqrt
	return inX * fastRcpSqrtNR2(inX);
}

//
// RCP
//

float rcpIEEEIntApproximation(float inX, const int inRcpConst)
{
	int x = asint(inX);
	x = inRcpConst - x;
	return asfloat(x);
}

float rcpNewtonRaphson(float inX, float inRcpX)
{
	return inRcpX * (-inRcpX * inX + 2.0f);
}

//
// Using 0 Newton Raphson iterations
// Relative error : < 0.4% over full
// Precise format : ~small float
// 1 ALU
//
float fastRcpNR0(float inX)
{
	float  xRcp = rcpIEEEIntApproximation(inX, IEEE_INT_RCP_CONST_NR0);
	return xRcp;
}

//
// Using 1 Newton Raphson iterations
// Relative error : < 0.02% over full
// Precise format : ~half float
// 3 ALU
//
float fastRcpNR1(float inX)
{
	float  xRcp = rcpIEEEIntApproximation(inX, IEEE_INT_RCP_CONST_NR1);
	xRcp = rcpNewtonRaphson(inX, xRcp);
	return xRcp;
}

//
// Using 2 Newton Raphson iterations
// Relative error : < 5.0e-005%  over full
// Precise format : ~full float
// 5 ALU
//
float fastRcpNR2(float inX)
{
	float  xRcp = rcpIEEEIntApproximation(inX, IEEE_INT_RCP_CONST_NR2);
	xRcp = rcpNewtonRaphson(inX, xRcp);
	xRcp = rcpNewtonRaphson(inX, xRcp);
	return xRcp;
}


//
// Trigonometric functions
//
static  const  float fsl_PI = 3.1415926535897932384626433f;
static  const  float fsl_HALF_PI = 0.5f * fsl_PI;

// 4th order polynomial approximation
// 4 VGRP, 16 ALU Full Rate
// 7 * 10^-5 radians precision
// Reference : Handbook of Mathematical Functions (chapter : Elementary Transcendental Functions), M. Abramowitz and I.A. Stegun, Ed.
float acosFast4(float inX)
{
	float x1 = abs(inX);
	float x2 = x1 * x1;
	float x3 = x2 * x1;
	float s;

	s = -0.2121144f * x1 + 1.5707288f;
	s = 0.0742610f * x2 + s;
	s = -0.0187293f * x3 + s;
	s = sqrt(1.0f - x1) * s;

	// acos function mirroring
	// check per platform if compiles to a selector - no branch neeeded
	return inX >= 0.0f ? s : fsl_PI - s;
}

// 4th order polynomial approximation
// 4 VGRP, 16 ALU Full Rate
// 7 * 10^-5 radians precision 
float asinFast4(float inX)
{
	float x = inX;

	// asin is offset of acos
	return fsl_HALF_PI - acosFast4(x);
}

// 4th order hyperbolical approximation
// 4 VGRP, 12 ALU Full Rate
// 7 * 10^-5 radians precision 
// Reference : Efficient approximations for the arctangent function, Rajan, S. Sichun Wang Inkol, R. Joyal, A., May 2006
float atanFast4(float inX)
{
	float  x = inX;
	return x*(-0.1784f * abs(x) - 0.0663f * x * x + 1.0301f);
}
#endif