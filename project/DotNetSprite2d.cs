using Godot;
using System;

public partial class DotNetSprite2d : Sprite2D
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		double rand = Random.Shared.NextDouble();
		if(rand > 0.17){
			double rand1 = (Random.Shared.NextDouble()*2-1)/17;
			double rand2 = (Random.Shared.NextDouble()*2-1)/17;
			double rand3 = (Random.Shared.NextDouble()*2-1)/17;
			Curve curveX = Texture.Get(CurveXyzTexture.PropertyName.CurveX).As<Curve>();
			Curve curveY = Texture.Get(CurveXyzTexture.PropertyName.CurveY).As<Curve>();
			Curve curveZ = Texture.Get(CurveXyzTexture.PropertyName.CurveZ).As<Curve>();
			float x = (float) Math.Clamp(curveX.GetPointPosition(0).Y +  rand1,0.0,0.99);
			float y = (float) Math.Clamp(curveY.GetPointPosition(0).Y +  rand2,0.0,0.99);
			float z = (float) Math.Clamp(curveZ.GetPointPosition(0).Y +  rand3,0.0,0.99);
			curveX.SetPointValue(0, x);
			curveY.SetPointValue(0, y);
			curveZ.SetPointValue(0, z);
		}
	}
}
