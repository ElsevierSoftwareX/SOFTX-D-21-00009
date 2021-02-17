<img src="images/abstract.png" width="512" style="width: 1024px; max-width: 1024px;">

———————————————
DOCUMENT TOWERS
———————————————

Document Towers is a software to visualize the three-dimensional geometry of paginated documents, that is the location and shape of the physical pages, text paragraphs, bitmap images, vector graphics, and, indeed, any information that can be spatially located.

Document Towers uses an architectural paradigm as cognitive model to represent document structures: objects-as-rooms, pages-as-floors, documents-as-towers, and libraries-as-cities.

The software obtains this information natively from Adobe InDesign IDML and ALTO files. A generic file format allows to import geometry data extracted by other software from further formats, such as PDF, Word, or even movie frames. The software is written in Matlab (R2018b).


———————————————
CONTENTS OF THE DISTRIBUTUION PACKAGE
———————————————

/src/Document_Towers_v20200110.mlappinstall
	Matlab application. It is easier to install the app than the files provided in the "code" folder. The app also contains all the files of the "code" folder; to see this, change the extension of this file to ZIP, and unzip the file.

	To install the app, click the APPS tab in the Matlab window, then "Install App", and select the application file "DocumentTowers" found in the in the folder created after unzipping. Click the "Document Towers" icon in the apps bar to run the application.

/src/code
	The individual files needed to run Document Towers. To install them click the Set Path button in the Environment panel of the Home tab in the Matlab window, and add the folders to the path:
		/3p/io/jsonlab-2.0
		/3p/io/xml_io_tools
		/3p/matlab/uitools/multiWaitbar
		/code/gx/docviz/towers/
		/code/gx/docviz/towers/colormaps
		/code/gx/docviz/towers/extract_geo
		/code/gx/docviz/towers/gui

/docs/help
	Open in a web browser the file index.html found in this folder to read the software documentation.

/docs/demo
	Demonstration files with document geometry data. For details read the file readme.txt found in the demo folder.


———————————————
CREDITS
———————————————

Vlad Atanasiu
atanasiu@alum.mit.edu
http://alum.mit.edu/www/atanasiu/
2021.01.11
