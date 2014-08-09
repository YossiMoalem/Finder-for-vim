"Descrption: vim plugins for Find files in bundles with regular expression
"Author:     xieyu3 at gmail dot com
"
"Usage:      in .vimrc, set g:paths and g:pathSep, like this way:
"            let g:paths="path1:path2:path3"
"            let g:pathSep=":"
" 			 in windows, you can set pathSep to ';' or whatever you like
"
"		     press <ctrl-f> to active the query, if find something,it  will show a
"		     output window that list the Found file path. 
"
"		     In output window, move to the line that you want open, press <Eneter> 
"		     to hide the output window and show that File in last window. 
"
"		     press <Space> 's behavior is same with <Enter> But keep the
"		     output window.

"default
if exists("pathSeperator") == 0
	let g:pathSeperator=":"
endif
if exists("paths") == 0
	let g:paths=""
endif

"Maps:
map <C-f> :py findFile()<CR>

python<<EOF
import vim
import os
import sys
import re
import fnmatch
import optparse

scriptdir = os.path.dirname(vim.eval('expand("<sfile>")'))
if scriptdir not in sys.path:
    sys.path.insert(0, scriptdir)

import MyFinder
import VimUi

pathSeperator = vim.eval('g:pathSeperator') 
paths = vim.eval('g:paths')
if len(paths) == 0 :
	print ("Root path is not set. Please set it in your .vimrc (example: let g:paths=/home/lala/dir1%s/home/lala/dir2/dir3)" % (pathSeperator))	
else:
	paths = paths.split(pathSeperator)

fileFinder = MyFinder.FileFinder(paths)

def findFile():
	(pattern, onlyfindInBufferList, matchingFunction) = _getFindFileArgs()
	results = []
	if pattern:
		results.extend( fileFinder.searchInBufferList(pattern, matchingFunction))
		if not onlyfindInBufferList:
			results.extend(fileFinder.search(pattern, matchingFunction))
		if results:
			#make it unique
			results =list(set(results))
			VimUi.showResults("findResults", results, "findFileHandler")
		else:
			vim.command('echo "So Sorry, cannot Find it :("')

def _getFindFileArgs():
	args = vim.eval('input("file pattern: ")')
	if not args:
		return (None, None)
	parser = optparse.OptionParser()
	parser.add_option("-b", dest = "onlyfindInBufferList", action = "store_true", help = "just find in current BufferList")
	parser.add_option("-c", dest = "caseSensetive", action = "store_true", help = "Case sensetive")
	parser.add_option("-e", dest = "exact", action = "store_true", help = "Exact regex, no leading or trainign characters")
	parser.add_option("-r", dest = "useRegex", action = "store_true", help = "Use Regex")
	(options, args) = parser.parse_args(args.split())
	if options.useRegex:
		matchAllPattern = ".*"
	else:
		matchAllPattern = "*"
	try:
		if options.exact:
			pattern = args[0]
		else:
			pattern = "%s%s%s" % (matchAllPattern, args[0], matchAllPattern)
	except:
		#just list all buffers if no pattern
		if options.onlyfindInBufferList:
			pattern = matchAllPattern
	if options.useRegex:
		matchingFunction = regexMatch
		try:
			if options.caseSensetive:
				pattern= re.compile(pattern)
			else:
				pattern = re.compile(pattern, re.IGNORECASE)
		except:
			print "Sorry, Can not understand this regular expression :("
			return (None, None)
	else:
			if options.caseSensetive:
				matchingFunction = shellMatch(caseSensetive = True)
			else:
				matchingFunction = shellMatch(caseSensetive = False)
	return (pattern, options.onlyfindInBufferList, matchingFunction)

def regexMatch(pattern, string):
	return pattern.match(string)

def shellMatch(caseSensetive):
	if caseSensetive:
		return lambda pattern, string: fnmatch.fnmatch(string, pattern)
	else:
		return lambda pattern, string: fnmatch.fnmatchcase(string, pattern)

def findFileHandler(line):
	filePath = line
	lineNum = None
	return (filePath, lineNum)
EOF
