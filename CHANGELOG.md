# Changelog

All notable changes to this project will be documented in this file. 

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.0.2] - 2025-04-18


### Fixed
- **Drawing History**: Fixed a bug related to saving and recalling drawing annotations, ensuring that the drawing state is correctly restored across sessions.
- **Undo/Redo Bug**: Addressed a bug where undo/redo functionality for annotations would sometimes fail under specific conditions.

### Documentation
- **Updated Documentation**: Clarified usage examples and added detailed comments in the codebase for better maintainability and ease of use.
- **Changelog Update**: This entry for version `0.0.2` has been added to provide detailed release notes.

## [0.0.1] - 2025-04-10

🎉 Initial release!

- **PDF Editing Features**: Introduced the ability to add and edit text boxes with resizing and repositioning.
- **Freehand Drawing**: Added freehand drawing with full undo/redo support.
- **Image Insertion**: Users can insert images into PDFs and manipulate their position and size.
- **Annotations**: Support for highlight and underline annotations with color customization.
- **Interactive Toolbar**: Dynamic toolbar for switching between drawing, text, annotation, and image modes.
- **Full PDF Saving**: Users can save their edits back to a new PDF file, with all modifications, including text, drawings, and annotations.
- **Multi-page Support**: Full support for multi-page PDFs with navigation and page-wise editing.
