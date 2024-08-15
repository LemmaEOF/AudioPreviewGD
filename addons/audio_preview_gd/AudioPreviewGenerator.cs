using Godot;
using System;

[Tool]
public partial class AudioPreviewGenerator
{
	private Node wrapped;
	
	public AudioPreviewGenerator()
	{
		this.wrapped = ClassDB.Instantiate("AudioPreviewGenerator").AsGodotObject() as Node;
	}
	
	public AudioPreviewGenerator(Node wrapped)
	{
		this.wrapped = wrapped;
	}
	
	public AudioPreview GeneratePreview(AudioStream stream)
	{
		return new AudioPreview(wrapped.Call("generate_preview", stream).AsGodotObject() as RefCounted);
	}
}
