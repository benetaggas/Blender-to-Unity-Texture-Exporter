import bpy
import json
import os
from bpy.props import StringProperty, FloatVectorProperty
from bpy.types import Panel, Operator
from bpy_extras.io_utils import ExportHelper

bl_info = {
    "name": "Blender Camo Exporter",
    "author": "Your Name",
    "version": (1, 0, 0),
    "blender": (3, 0, 0),
    "location": "Properties > Render",
    "description": "Export camo patterns and colors to Unity-compatible JSON",
    "category": "Import-Export"
}

# Define property group for camouflage colors
class CamouflageColorProperties(bpy.types.PropertyGroup):
    white_color: FloatVectorProperty(
        name="White Replacement",
        subtype='COLOR',
        default=(1.0, 1.0, 1.0),
        min=0.0, max=1.0,
        description="Color to replace white areas in the camouflage texture"
    )
    
    gray_color: FloatVectorProperty(
        name="Gray Replacement",
        subtype='COLOR',
        default=(0.5, 0.5, 0.5),
        min=0.0, max=1.0,
        description="Color to replace gray areas in the camouflage texture"
    )
    
    black_color: FloatVectorProperty(
        name="Black Replacement",
        subtype='COLOR',
        default=(0.0, 0.0, 0.0),
        min=0.0, max=1.0,
        description="Color to replace black areas in the camouflage texture"
    )
    
    texture_path: StringProperty(
        name="Camouflage Texture",
        description="Path to the camouflage texture",
        default="",
        subtype='FILE_PATH'
    )

# Export operator
class EXPORT_OT_camouflage_data(Operator, ExportHelper):
    """Export camouflage color data for Unity"""
    bl_idname = "export.camouflage_data"
    bl_label = "Export Camouflage Data"
    
    filename_ext = ".json"
    
    filter_glob: StringProperty(
        default="*.json",
        options={'HIDDEN'},
        maxlen=255
    )
    
    def execute(self, context):
        scene = context.scene
        camo_props = scene.camouflage_properties
        
        # Prepare data for export
        data = {
            "whiteColor": [camo_props.white_color[0], camo_props.white_color[1], camo_props.white_color[2]],
            "grayColor": [camo_props.gray_color[0], camo_props.gray_color[1], camo_props.gray_color[2]],
            "blackColor": [camo_props.black_color[0], camo_props.black_color[1], camo_props.black_color[2]]
        }
        
        # Export as JSON
        with open(self.filepath, 'w') as f:
            json.dump(data, f, indent=4)
            
        self.report({'INFO'}, f"Camouflage data exported to {self.filepath}")
        return {'FINISHED'}

# UI Panel
class VIEW3D_PT_camouflage_panel(Panel):
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = "Camouflage"
    bl_label = "Camouflage Editor"
    
    def draw(self, context):
        layout = self.layout
        scene = context.scene
        camo_props = scene.camouflage_properties
        
        # Texture selection
        layout.label(text="Texture:")
        layout.prop(camo_props, "texture_path", text="")
        
        # Color settings
        layout.label(text="Color Replacements:")
        layout.prop(camo_props, "white_color")
        layout.prop(camo_props, "gray_color")
        layout.prop(camo_props, "black_color")
        
        # Preview material creation
        layout.separator()
        layout.operator("material.create_camouflage_preview", text="Create Preview Material")
        
        # Export button
        layout.separator()
        layout.operator("export.camouflage_data", text="Export to Unity")

# Create preview material
class MATERIAL_OT_create_camouflage_preview(Operator):
    """Create a preview material with the current camouflage settings"""
    bl_idname = "material.create_camouflage_preview"
    bl_label = "Create Camouflage Preview"
    
    def execute(self, context):
        scene = context.scene
        camo_props = scene.camouflage_properties
        
        # Check if texture path is set
        if not camo_props.texture_path or not os.path.exists(bpy.path.abspath(camo_props.texture_path)):
            self.report({'ERROR'}, "Please select a valid texture file")
            return {'CANCELLED'}
        
        # Create new material
        mat_name = "CamouflagePreview"
        mat = bpy.data.materials.get(mat_name)
        if not mat:
            mat = bpy.data.materials.new(name=mat_name)
        
        # Enable nodes
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        # Clear nodes
        for node in nodes:
            nodes.remove(node)
        
        # Create nodes
        output = nodes.new(type='ShaderNodeOutputMaterial')
        bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
        tex_image = nodes.new(type='ShaderNodeTexImage')
        mix_rgb = nodes.new(type='ShaderNodeMixRGB')
        mix_rgb.blend_type = 'MIX'
        
        # Set texture
        try:
            tex_image.image = bpy.data.images.load(bpy.path.abspath(camo_props.texture_path))
        except:
            self.report({'ERROR'}, "Failed to load texture")
            return {'CANCELLED'}
        
        # Create separate RGB node
        separate_rgb = nodes.new(type='ShaderNodeSeparateRGB')
        
        # Create color nodes
        white_rgb = nodes.new(type='ShaderNodeRGB')
        white_rgb.outputs[0].default_value = (*camo_props.white_color, 1.0)
        
        gray_rgb = nodes.new(type='ShaderNodeRGB')
        gray_rgb.outputs[0].default_value = (*camo_props.gray_color, 1.0)
        
        black_rgb = nodes.new(type='ShaderNodeRGB')
        black_rgb.outputs[0].default_value = (*camo_props.black_color, 1.0)
        
        # Mix nodes
        mix_white_gray = nodes.new(type='ShaderNodeMixRGB')
        mix_white_gray.blend_type = 'MIX'
        
        mix_final = nodes.new(type='ShaderNodeMixRGB')
        mix_final.blend_type = 'MIX'
        
        # Link nodes
        links.new(tex_image.outputs[0], separate_rgb.inputs[0])
        
        # Link white and gray mix
        links.new(separate_rgb.outputs[0], mix_white_gray.inputs[0])  # R channel as factor
        links.new(white_rgb.outputs[0], mix_white_gray.inputs[1])
        links.new(gray_rgb.outputs[0], mix_white_gray.inputs[2])
        
        # Link final mix
        links.new(separate_rgb.outputs[2], mix_final.inputs[0])  # B channel as factor
        links.new(mix_white_gray.outputs[0], mix_final.inputs[1])
        links.new(black_rgb.outputs[0], mix_final.inputs[2])
        
        # Link to output
        links.new(mix_final.outputs[0], bsdf.inputs[0])
        links.new(bsdf.outputs[0], output.inputs[0])
        
        # Position nodes
        output.location = (300, 0)
        bsdf.location = (100, 0)
        tex_image.location = (-600, 200)
        separate_rgb.location = (-400, 200)
        
        white_rgb.location = (-400, 0)
        gray_rgb.location = (-400, -100)
        black_rgb.location = (-400, -200)
        
        mix_white_gray.location = (-200, 0)
        mix_final.location = (-50, 0)
        
        # Assign to selected objects
        for obj in context.selected_objects:
            if obj.type == 'MESH':
                if obj.data.materials:
                    obj.data.materials[0] = mat
                else:
                    obj.data.materials.append(mat)
        
        self.report({'INFO'}, "Camouflage preview material created")
        return {'FINISHED'}

# Registration
classes = (
    CamouflageColorProperties,
    EXPORT_OT_camouflage_data,
    VIEW3D_PT_camouflage_panel,
    MATERIAL_OT_create_camouflage_preview,
)

def register():
    for cls in classes:
        bpy.utils.register_class(cls)
    bpy.types.Scene.camouflage_properties = bpy.props.PointerProperty(type=CamouflageColorProperties)

def unregister():
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
    del bpy.types.Scene.camouflage_properties

if __name__ == "__main__":
    register() 