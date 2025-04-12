using UnityEngine;

[CreateAssetMenu(fileName = "NewCamouflageColorData", menuName = "Camouflage/Color Data")]
public class CamouflageColorData : ScriptableObject
{
    [Header("Camouflage Colors")]
    [Tooltip("Color to replace white areas in the texture")]
    public Color whiteReplacement = Color.white;
    
    [Tooltip("Color to replace gray areas in the texture")]
    public Color grayReplacement = Color.gray;
    
    [Tooltip("Color to replace black areas in the texture")]
    public Color blackReplacement = Color.black;
}