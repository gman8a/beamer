#! /bin/bash
#
# program file:
# date:
# author:
# purpose:
# ref:
# https://marc.waeckerlin.org/computer/blog/parsing_of_query_string_in_bash_cgi_scripts

. urlcoder.sh
cgi_getvars POST beamerInput
 
/bin/cat <<EOF
Content-type: text/html


<html>
<head>
	<title>
		Beamer, Civil Engineering Software by Gary Argraves
	</title>
</head>

<body>
	<h1>Beamer, Civil Engineering Software, by GaryArgraves@gmail.com</h1>

	<h2>Beamer Input</h2>
	<form method="POST" action="/cgi-bin/g/beamer.cgi">
		<textarea name="beamerInput" cols="80" rows="60">
		${beamerInput}
		</textarea>
		<br>
		<input type="submit" value="Re-Submit" />
	</form>

	<h2>Beamer Output</h2>
	<pre>
	$(echo "${beamerInput}"|./beamcpm_plot)
	</pre>
 
</body>
</html>
EOF

