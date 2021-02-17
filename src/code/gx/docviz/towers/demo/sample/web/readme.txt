DOCUMENT TOWERS DISPLAYED IN A WEB BROWSER

This code illustrates the display of Document Towers in a web browser. It also shows performance issues with increasing file size.


towers.html
	Open this file in a web browser to show a default sample document geometry with small size (4kB).

towers.html?url=./data/default - large.json
	Append in the web browser URL bar the extension specified above to open a large geometry file (1.8 MB; the data reproduces multiple times the data from the file "default - large.json"). Most likely the web browser will stop before loading the entire data, illustrating performance issues with loading high amounts of geometry data.

towers.html?url=./data/atanasiu2013expertbytes - frames pretty.json
	Data (76kB) from a published book (https://www.amazon.com/Expert-Bytes-Expertise-Documents-Resources-dp-1466591900/dp/1466591900/).
