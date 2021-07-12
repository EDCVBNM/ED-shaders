#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform float threshold < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Brightness";
	ui_min = 0.0; ui_max = 1.0;
> = 0.1;

uniform int steps <
    ui_label = "Amount of Shades";
    ui_type  = "combo";
    ui_items = " None\0 1\0 2\0";
> = 2;

texture blendTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler blendSamp { Texture = blendTex; };

float3 preEdgeBlend(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	if(pos.x % 2 <= 1 && pos.y % 2 <= 1)
	{
		return tex2D(ReShade::BackBuffer, texcoord).rgb;
	}
	else
	{
		return 0;
	}
}

float3 patternShading(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	int pattern;
	float edgeBlend = dot(tex2D(blendSamp, texcoord).rgb, 1.0 / 3.0), luma = dot(tex2D(ReShade::BackBuffer, texcoord).rgb, 1.0 / 3.0);

	edgeBlend = max(edgeBlend, dot(tex2D(blendSamp, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y)).rgb, 1.0 / 3.0));
	edgeBlend = max(edgeBlend, dot(tex2D(blendSamp, float2(texcoord.x, texcoord.y + BUFFER_RCP_HEIGHT)).rgb, 1.0 / 3.0));
	edgeBlend = max(edgeBlend, dot(tex2D(blendSamp, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y + BUFFER_RCP_HEIGHT)).rgb, 1.0 / 3.0));

	if(pos.x % 2 <= 1 && pos.y % 2 <= 1)
	{
		pattern = 0;
	}
	else
	{
		pattern = 1;
	}

	if(steps == 0)
	{
		pattern = ceil(1.0 - step(luma, threshold));
	}
	else if(steps == 1)
	{
		if(luma <= threshold)
		{
			pattern = 0;
		}
		else if(luma >= threshold * 3)
		{
			pattern = 1;
		}
	}
	else
	{
		if(luma <= threshold)
		{
			pattern = 0;
		}
		else if(edgeBlend <= threshold * 2)
		{
			pattern = 1 - pattern;
		}
		else if(luma >= threshold * 4)
		{
			pattern = 1;
		}
	}

	return pattern;
}

technique PatternShading
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = preEdgeBlend;
		RenderTarget = blendTex;
	}

	pass pass1
	{
		VertexShader = PostProcessVS;
		PixelShader = patternShading;
	}
}
