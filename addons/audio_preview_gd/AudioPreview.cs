using Godot;
using System;

[Tool]
public partial class AudioPreview
{
	private RefCounted wrapped;
	
	public AudioPreview(RefCounted wrapped)
	{
		this.wrapped = wrapped;
	}
	
	public double GetLength()
	{
		return (double) wrapped.Call("get_length");
	}
	
	public double GetMax(double start, double end)
	{
		return (double) wrapped.Call("get_max", start, end);
	}
	
	public double GetMin(double start, double end)
	{
		return (double) wrapped.Call("get_min", start, end);
	}
}
