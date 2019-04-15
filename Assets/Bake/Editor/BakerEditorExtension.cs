using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(SaveRenderTexture))]//拡張するクラスを指定
public class SaveRenderTextureEditorExtension : Editor {

    public override void OnInspectorGUI(){
        //元のInspector部分を表示
        base.OnInspectorGUI ();
        
        SaveRenderTexture baker = target as SaveRenderTexture;
        
        //ボタンを表示
        if (GUILayout.Button("Save Render Texture")){
            baker.Save();
        }  
    }

} 