using UnityEngine;

[RequireComponent(typeof(Renderer))]
public class CamouflageMaterialController : MonoBehaviour
{
    [Header("Camouflage Settings")]
    [Tooltip("Reference to the CamouflageColorData scriptable object")]
    public CamouflageColorData colorData;
    
    [Tooltip("Index of the material to modify (leave at 0 if only one material)")]
    public int materialIndex = 0;
    
    // Material property names
    private static readonly int WhiteReplaceColorProp = Shader.PropertyToID("_WhiteReplaceColor");
    private static readonly int GrayReplaceColorProp = Shader.PropertyToID("_GrayReplaceColor"); 
    private static readonly int BlackReplaceColorProp = Shader.PropertyToID("_BlackReplaceColor");
    
    // References
    private Renderer _renderer;
    private MaterialPropertyBlock _propertyBlock;
    
    private void Awake()
    {
        _renderer = GetComponent<Renderer>();
        _propertyBlock = new MaterialPropertyBlock();
    }
    
    private void Start()
    {
        UpdateMaterialColors();
    }
    
    public void UpdateMaterialColors()
    {
        if (colorData == null || _renderer == null)
        {
            Debug.LogWarning("Missing references in CamouflageMaterialController", this);
            return;
        }
        
        // Get the material property block
        _renderer.GetPropertyBlock(_propertyBlock, materialIndex);
        
        // Set the replacement colors from the scriptable object
        _propertyBlock.SetColor(WhiteReplaceColorProp, colorData.whiteReplacement);
        _propertyBlock.SetColor(GrayReplaceColorProp, colorData.grayReplacement);
        _propertyBlock.SetColor(BlackReplaceColorProp, colorData.blackReplacement);
        
        // Apply the modified property block to the renderer
        _renderer.SetPropertyBlock(_propertyBlock, materialIndex);
    }
    
    // This will update the material when values change in the editor
    private void OnValidate()
    {
        if (Application.isPlaying && _renderer != null && colorData != null)
        {
            UpdateMaterialColors();
        }
    }
} 