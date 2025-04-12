using UnityEngine;
using System.IO;
using UnityEditor;

#if UNITY_EDITOR
public class CamouflageDataImporter : EditorWindow
{
    private string jsonFilePath = "";
    private CamouflageColorData colorData;
    private Material targetMaterial;

    [MenuItem("Tools/Camouflage/Import Blender Camouflage Data")]
    public static void ShowWindow()
    {
        GetWindow<CamouflageDataImporter>("Camouflage Importer");
    }

    private void OnGUI()
    {
        GUILayout.Label("Camouflage Data Importer", EditorStyles.boldLabel);
        
        EditorGUILayout.Space();
        
        EditorGUILayout.BeginHorizontal();
        jsonFilePath = EditorGUILayout.TextField("JSON File Path", jsonFilePath);
        if (GUILayout.Button("Browse", GUILayout.Width(60)))
        {
            string path = EditorUtility.OpenFilePanel("Select Camouflage JSON Data", "", "json");
            if (!string.IsNullOrEmpty(path))
            {
                jsonFilePath = path;
            }
        }
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.Space();
        
        colorData = (CamouflageColorData)EditorGUILayout.ObjectField(
            "Target Scriptable Object", colorData, typeof(CamouflageColorData), false);
            
        targetMaterial = (Material)EditorGUILayout.ObjectField(
            "Target Material", targetMaterial, typeof(Material), false);
        
        EditorGUILayout.Space();
        
        EditorGUI.BeginDisabledGroup(string.IsNullOrEmpty(jsonFilePath) || colorData == null);
        if (GUILayout.Button("Import Data"))
        {
            ImportData();
        }
        EditorGUI.EndDisabledGroup();
        
        EditorGUILayout.Space();
        
        EditorGUI.BeginDisabledGroup(colorData == null || targetMaterial == null);
        if (GUILayout.Button("Apply To Material"))
        {
            ApplyToMaterial();
        }
        EditorGUI.EndDisabledGroup();
    }

    private void ImportData()
    {
        if (!File.Exists(jsonFilePath))
        {
            EditorUtility.DisplayDialog("Error", "File not found at: " + jsonFilePath, "OK");
            return;
        }

        try
        {
            string jsonContent = File.ReadAllText(jsonFilePath);
            CamouflageColorDataJson dataFromJson = JsonUtility.FromJson<CamouflageColorDataJson>(jsonContent);
            
            // Apply imported data to ScriptableObject
            Undo.RecordObject(colorData, "Import Camouflage Data");
            
            colorData.whiteReplacement = new Color(
                dataFromJson.whiteColor[0], 
                dataFromJson.whiteColor[1], 
                dataFromJson.whiteColor[2], 
                1.0f);
                
            colorData.grayReplacement = new Color(
                dataFromJson.grayColor[0], 
                dataFromJson.grayColor[1], 
                dataFromJson.grayColor[2], 
                1.0f);
                
            colorData.blackReplacement = new Color(
                dataFromJson.blackColor[0], 
                dataFromJson.blackColor[1], 
                dataFromJson.blackColor[2], 
                1.0f);
            
            EditorUtility.SetDirty(colorData);
            AssetDatabase.SaveAssets();
            
            EditorUtility.DisplayDialog("Success", "Data imported successfully!", "OK");
        }
        catch (System.Exception e)
        {
            EditorUtility.DisplayDialog("Error", "Failed to import data: " + e.Message, "OK");
        }
    }
    
    private void ApplyToMaterial()
    {
        if (targetMaterial == null || colorData == null)
            return;
            
        Undo.RecordObject(targetMaterial, "Apply Camouflage Colors");
        
        targetMaterial.SetColor("_WhiteReplaceColor", colorData.whiteReplacement);
        targetMaterial.SetColor("_GrayReplaceColor", colorData.grayReplacement);
        targetMaterial.SetColor("_BlackReplaceColor", colorData.blackReplacement);
        
        EditorUtility.SetDirty(targetMaterial);
    }
}

// Class to match the JSON structure from Blender
[System.Serializable]
public class CamouflageColorDataJson
{
    public float[] whiteColor = new float[3];
    public float[] grayColor = new float[3];
    public float[] blackColor = new float[3];
}
#endif