#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform float3 color1 < __UNIFORM_COLOR_FLOAT3
	ui_type = "color";
> = float3(0.0, 1.0, 1.0);

uniform float3 color2 < __UNIFORM_COLOR_FLOAT3
	ui_type = "color";
> = float3(1.0, 0.0, 1.0);

uniform float3 color3 < __UNIFORM_COLOR_FLOAT3
	ui_type = "color";
> = float3(1.0, 1.0, 0.0);

uniform int gradSharp < __UNIFORM_SLIDER_INT1
	ui_label = "Gradient sharpness";
	ui_min = 1; ui_max = 100;
> = 10;

uniform float angle < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

uniform float position < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 4.0;
> = 1.0;

uniform int blendType <
    ui_label = "Blend type";
    ui_type  = "combo";
    ui_items = "None\0 Add\0 Multiply\0 50/50\0";
> = 1;

float3 threeColorGradient(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float angleMask = lerp(texcoord.x, texcoord.y, angle) / position,
		  gradientMask = pow((angleMask * (1.0 - angleMask)) * 4.0, gradSharp);

	float3 gradientColor;

	if(angleMask < 0.5)
	{
		gradientColor = (1.0 - gradientMask) * color1;
	}
	else
	{
		gradientColor = (1.0 - gradientMask) * color3;
	}

	if(blendType == 0)
	{
		return gradientColor + gradientMask * color2;
	}
	else if(blendType == 1)
	{
		return tex2D(ReShade::BackBuffer, texcoord).rgb + (gradientColor + gradientMask * color2);
	}
	else if(blendType == 2)
	{
		return tex2D(ReShade::BackBuffer, texcoord).rgb * (gradientColor + gradientMask * color2);
	}
	else
	{
		return (tex2D(ReShade::BackBuffer, texcoord).rgb + (gradientColor + gradientMask * color2)) / 2;
	}
}

technique ThreeColorGradient
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = threeColorGradient;
	}
}
