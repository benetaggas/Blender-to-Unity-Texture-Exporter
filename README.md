## Technical Specifications

- **Unity Version**: 6.0.0.41f1
- **Render Pipeline**: Universal Render Pipeline (URP) 17.0.4
- **Input System**: Unity Input System 1.13.1
- **Visual Effects**: VFX Graph 17.0.4

## Installation & Setup

### Prerequisites
- Unity 6.0+ with URP
- Blender 3.0+ (for camouflage design)
- Python 3.12+ (for MCP server)
- Git CLI

### Camouflage System Setup

1. **Blender Add-on Installation**:
   - Import `CamouflageExporter.py` into Blender
   - Enable the add-on in Edit > Preferences > Add-ons
   - Access via 3D Viewport sidebar "Camouflage" tab

2. **Unity Integration**:
   - All required scripts are included in `Assets/Scripts/`
   - Use Tools > Camouflage menu for data import
   - Create materials using the included camouflage shader

## Usage Examples

### Creating Camouflage Patterns

1. **In Blender**:
   - Design pattern using black/gray/white colors
   - Set replacement colors in Camouflage tab
   - Export JSON data for Unity

2. **In Unity**:
   - Import via Tools > Camouflage > Import Blender Camouflage Data
   - Apply to materials or GameObjects
   - Use `CamouflageController` for runtime changes

## Workflow Integration

The project demonstrates a complete pipeline:

1. **Design Phase**: Create camouflage patterns in Blender
2. **Import Phase**: Seamlessly transfer data to Unity
3. **Application Phase**: Apply patterns to 3D models
4. **AI Enhancement**: Use AI to automate and enhance the workflow
5. **Testing Phase**: Validate patterns in the LilaTest scene

## Advanced Features

- **Material Instancing**: Efficient rendering for multiple camouflage variants
- **Runtime Color Switching**: Dynamic camouflage changes during gameplay
- **Batch Asset Management**: Process multiple patterns simultaneously
- **AI Script Generation**: Automatically create supporting scripts
- **Scene Management**: AI-controlled scene setup and configuration

## Development Notes

This project serves as a testbed for:
- Advanced material systems in Unity 6
- Cross-platform asset pipeline (Blender ↔ Unity)
- AI-assisted game development workflows
- Modern Unity architecture patterns

## Requirements

- **Unity**: 6.0+ with URP
- **Blender**: 3.0+ (for pattern design)
- **Python**: 3.12+ (for MCP server)
- **MCP Client**: Claude Desktop, Cursor, or compatible client

## Contributing

This project demonstrates cutting-edge Unity development techniques. Contributions should focus on:
- Enhancing the camouflage system
- Improving AI integration
- Adding new automation features
- Optimizing performance

## License

MIT License - See individual component licenses for specific terms.

---

*This project showcases the future of game development: seamless artistic workflows combined with AI-powered automation.*
