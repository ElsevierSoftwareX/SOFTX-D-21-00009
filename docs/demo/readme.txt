DOCUMENT TOWERS DEMO FILES
==========================


/book
	Visualize the geometry of an entire published book.

/sample
	Visualize the geometry of a sample document.

	/sources
		Source files.

		sample.indd
			Adobe InDesign CS6 source file for the sample document.
		sample_frames_indesign_cs6.png
			Screenshot of the InDesign interface showing object boundaries, called frames (in blue). Some of the objects have the same size as the page margins, in red. Page 11 shows non-rectangular frames; the question mark is a vectorized font. "Jesus Loves You" on page 10 is a typeface by Lucas de Groot.

		sample.idml
			The InDesign document saved in the IDML format.
		sample.zip
			The IDML file with the extension changed to ZIP.
		/sample-unzipped
			Contents of the unzipped IDML file, showing its various XML components from which the geomtery data used by Document Towers for visualization is obtained.
		sample_geometry_from_idml.json
			Document geometry data extracted by Document Towers (via Menu > Geometry > Extract > IDML) from the file sample.idml. This is the geometry format recognized and used by the Document Towers.
		sample_geometry_from_idml_tagged.json
			Manually added tags, describing various object types to illustrate the use of tags, which are displayed next to the document tower.

		sample.pdf
			The InDesign document saved in PDF format.
		sample_geometry_from_pdf.json
			The geometry data extracted from the PDF file. (Via a proprietary API to the PDF analysis software Enlighter of the Sugarcube company [https://www.sugarcube.ch].)

	/tests
		Files for testing the Document Towers visualization according to different criteria. Because Document Towers processes all the documents in a folder, a topical organization is provided here for convenience.

		sample.pdf
			This is the PDF output of the InDesign document, included in each test folder. The visualization is hyperlinked to the PDF, such that when a page number or a tag (if available) is clicked, the respective page of the PDF is displayed in a web browser.
		/single_idml_source
			Test the extraction of document geometry from a IDML file (via Menu > Geometry > Extract > IDML).
		/single_geometry_from_idml
			Visualize the document geometry obtained from a IDML file.
		/single_geometry_from_pdf
			Visualize the document geometry obtained from a PDF file.
		/comparison_idml_pdf
			Compare the differences in the extracted document structures when using the information provided in the IDML and the PDF files.
		/multiples
			See how the visual appearance of multiple documents visualized in Document Towers.
		/tagged
			See how tags are encoded in the JSON geometry file and how to use them in the Document Towers visualization.

	/web
		Visualize the sample InDesign document geometry in a Web browser using JavaScript.

		sample_geometry_from_javascript.png
			Screenshot of the expected document visualization using JavaScript.


