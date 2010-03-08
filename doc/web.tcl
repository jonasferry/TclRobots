proc header {title} {
    return "
<?xml version='1.0' encoding='ISO-8859-1'?>
<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN'
'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>
<html  xmlns='http://www.w3.org/1999/xhtml' xml:lang='en' lang='en'>
<head>
<meta http-equiv='Content-Style-Type' content='text/css' />
<meta http-equiv='Content-type' content='text/html; charset=ISO-8859-1' />
<link rel='stylesheet' href='./tclrobots.css' type='text/css' />
<title>$title</title>
<!-- Source: ./ -->
<!-- Generated with ROBODoc Version 4.99.38 (May  2 2009) -->
</head>
<body>
<div id='logo'>
<a name='robo_top_of_doc'></a>
</div> <!-- logo -->
"
}

proc footer {} {
    return "
<div id='footer'>
<p>Generated with ROBODoc V4.99.38
</p>
</div> <!-- footer -->
</body>
</html>
"
}

proc navigation {} {

}