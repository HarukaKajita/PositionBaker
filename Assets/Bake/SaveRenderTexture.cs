
using UnityEngine;
using System.Collections;
using System.IO;
 
public class SaveRenderTexture : MonoBehaviour {
 
    public RenderTexture RenderTextureRef;
	public string filename = "BakedTexture_200";
 
    public void Save()
    {
        Texture2D tex = new Texture2D(RenderTextureRef.width, RenderTextureRef.height, TextureFormat.RGB24, false, false);
        RenderTexture.active = RenderTextureRef;
        tex.filterMode = FilterMode.Point;
        tex.ReadPixels(new Rect(0, 0, RenderTextureRef.width, RenderTextureRef.height), 0, 0, false);
        tex.Apply();
 
        // Encode texture into PNG
        byte[] bytes = tex.EncodeToPNG();
        Object.DestroyImmediate(tex);
 
        File.WriteAllBytes(Application.dataPath + "/BakeTextures/" + filename+".png", bytes);
    }
}