using UnityEngine;
using System.IO;
using UnityEditor;

#if UNITY_EDITOR
public class CamouflageDataImporter : EditorWindow
{
    private string jsonFilePath = "";
    private CamouflageColorData colorData;
    private Material targetMaterial;
    private string variantName = "Variant";
    private bool autoCreateScriptableObject = true;

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
        
        autoCreateScriptableObject = EditorGUILayout.Toggle("Auto Create ScriptableObject", autoCreateScriptableObject);
        
        if (autoCreateScriptableObject)
        {
            variantName = EditorGUILayout.TextField("Variant Name", variantName);
        }
        else
        {
            colorData = (CamouflageColorData)EditorGUILayout.ObjectField(
                "Target Scriptable Object", colorData, typeof(CamouflageColorData), false);
        }
            
        targetMaterial = (Material)EditorGUILayout.ObjectField(
            "Target Material", targetMaterial, typeof(Material), false);
        
        EditorGUILayout.Space();
        
        EditorGUI.BeginDisabledGroup(string.IsNullOrEmpty(jsonFilePath) || (!autoCreateScriptableObject && colorData == null));
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
            
            // Create new ScriptableObject if auto-create is enabled
            if (autoCreateScriptableObject)
            {
                // Ensure the directory exists
                string dirPath = "Assets/ScriptableObjects/Camo";
                if (!Directory.Exists(Path.Combine(Application.dataPath, "ScriptableObjects/Camo")))
                {
                    Directory.CreateDirectory(Path.Combine(Application.dataPath, "ScriptableObjects/Camo"));
                    AssetDatabase.Refresh();
                }
                
                // Find a unique name for the new asset
                string baseName = "Camo_" + variantName;
                string assetName = baseName;
                int counter = 1;
                string assetPath = Path.Combine(dirPath, assetName + ".asset");
                
                while (File.Exists(assetPath))
                {
                    assetName = baseName + counter;
                    assetPath = Path.Combine(dirPath, assetName + ".asset");
                    counter++;
                }
                
                // Create and save the ScriptableObject
                colorData = CreateInstance<CamouflageColorData>();
                AssetDatabase.CreateAsset(colorData, assetPath);
            }
            
            // Apply imported data to ScriptableObject
            if (colorData != null)
            {
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
                
                string message = autoCreateScriptableObject 
                    ? "Data imported and new ScriptableObject created at: " + AssetDatabase.GetAssetPath(colorData)
                    : "Data imported successfully!";
                
                EditorUtility.DisplayDialog("Success", message, "OK");
            }
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
    
    // Batch process multiple JSON files
    [MenuItem("Tools/Camouflage/Batch Import Blender Camouflage Data")]
    public static void BatchImport()
    {
        string folder = EditorUtility.OpenFolderPanel("Select Folder with JSON Files", "", "");
        if (string.IsNullOrEmpty(folder))
            return;
            
        string[] jsonFiles = Directory.GetFiles(folder, "*.json");
        if (jsonFiles.Length == 0)
        {
            EditorUtility.DisplayDialog("No Files Found", "No JSON files found in the selected folder.", "OK");
            return;
        }
        
        // Ensure the target directory exists
        string targetDir = "Assets/ScriptableObjects/Camo";
        if (!Directory.Exists(Path.Combine(Application.dataPath, "ScriptableObjects/Camo")))
        {
            Directory.CreateDirectory(Path.Combine(Application.dataPath, "ScriptableObjects/Camo"));
            AssetDatabase.Refresh();
        }
        
        int successCount = 0;
        foreach (string jsonFile in jsonFiles)
        {
            try
            {
                string jsonContent = File.ReadAllText(jsonFile);
                CamouflageColorDataJson dataFromJson = JsonUtility.FromJson<CamouflageColorDataJson>(jsonContent);
                
                // Extract filename without extension to use as variant name
                string fileName = Path.GetFileNameWithoutExtension(jsonFile);
                string assetName = "Camo_" + fileName;
                string assetPath = Path.Combine(targetDir, assetName + ".asset");
                
                // Check if asset already exists, if so, add a number
                int counter = 1;
                while (File.Exists(assetPath))
                {
                    assetName = "Camo_" + fileName + counter;
                    assetPath = Path.Combine(targetDir, assetName + ".asset");
                    counter++;
                }
                
                // Create and populate the ScriptableObject
                CamouflageColorData newColorData = CreateInstance<CamouflageColorData>();
                newColorData.whiteReplacement = new Color(
                    dataFromJson.whiteColor[0], 
                    dataFromJson.whiteColor[1], 
                    dataFromJson.whiteColor[2], 
                    1.0f);
                    
                newColorData.grayReplacement = new Color(
                    dataFromJson.grayColor[0], 
                    dataFromJson.grayColor[1], 
                    dataFromJson.grayColor[2], 
                    1.0f);
                    
                newColorData.blackReplacement = new Color(
                    dataFromJson.blackColor[0], 
                    dataFromJson.blackColor[1], 
                    dataFromJson.blackColor[2], 
                    1.0f);
                
                // Save the asset
                AssetDatabase.CreateAsset(newColorData, assetPath);
                successCount++;
            }
            catch (System.Exception e)
            {
                Debug.LogError($"Failed to import {jsonFile}: {e.Message}");
            }
        }
        
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        
        EditorUtility.DisplayDialog("Batch Import Complete", 
            $"Successfully imported {successCount} out of {jsonFiles.Length} files.", "OK");
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