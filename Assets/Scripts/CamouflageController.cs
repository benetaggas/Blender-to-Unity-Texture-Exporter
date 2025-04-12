using UnityEngine;

public class CamouflageController : MonoBehaviour
{
    [Header("Camouflage Setup")]
    public CamouflageColorData colorData;
    public Material camouflageBaseMaterial;
    public MeshRenderer targetRenderer;
    public int materialIndex = 0;
    
    private Material instancedMaterial;
    
    [Header("Runtime Options")]
    public bool updateColors = false;

    private void Start()
    {
        if (targetRenderer == null)
        {
            targetRenderer = GetComponent<MeshRenderer>();
            if (targetRenderer == null)
            {
                Debug.LogError("No MeshRenderer found on this GameObject or assigned to targetRenderer.");
                return;
            }
        }
        
        if (camouflageBaseMaterial == null)
        {
            Debug.LogError("No camouflage material assigned.");
            return;
        }
        
        // Create a material instance
        instancedMaterial = new Material(camouflageBaseMaterial);
        
        // Replace the material on the renderer
        Material[] materials = targetRenderer.sharedMaterials;
        if (materialIndex < materials.Length)
        {
            materials[materialIndex] = instancedMaterial;
            targetRenderer.sharedMaterials = materials;
            
            // Apply initial color settings
            if (colorData != null)
            {
                ApplyColorData();
            }
        }
        else
        {
            Debug.LogError("Material index out of range.");
        }
    }
    
    private void Update()
    {
        if (updateColors && colorData != null && instancedMaterial != null)
        {
            ApplyColorData();
        }
    }
    
    public void ApplyColorData()
    {
        instancedMaterial.SetColor("_WhiteReplaceColor", colorData.whiteReplacement);
        instancedMaterial.SetColor("_GrayReplaceColor", colorData.grayReplacement);
        instancedMaterial.SetColor("_BlackReplaceColor", colorData.blackReplacement);
    }
    
    public void SetColorData(CamouflageColorData newColorData)
    {
        colorData = newColorData;
        if (instancedMaterial != null)
        {
            ApplyColorData();
        }
    }
}