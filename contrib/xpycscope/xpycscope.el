; -*-Emacs-Lisp-*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; File:         xpycscope.el
; RCS:          $RCSfile: xcscope.el,v $ $Revision: 1.14 $ $Date: 2002/04/10 16:59:00 $ $Author: darrylo $
; Description:  pycscope interface for (X)Emacs
; Author:       Darryl Okahata
; Created:      Wed Apr 19 17:03:38 2000
; Modified:     Thu Apr  4 17:22:22 2002 (Darryl Okahata) darrylo@soco.agilent.com
; Language:     Emacs-Lisp
; Package:      N/A
; Status:       Experimental
;
; (C) Copyright 2000, 2001, 2002, Darryl Okahata <darrylo@sonic.net>,
;     all rights reserved.
; GNU Emacs enhancements (C) Copyright 2001,
;         Triet H. Lai <thlai@mail.usyd.edu.au>
; Fuzzy matching and navigation code (C) Copyright 2001,
;         Steven Elliott <selliott4@austin.rr.com>
; Pycscope support (C) Copyright 2012,
;         Peter Portante <peter.a.portante@gmail.com>
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ALPHA VERSION 0.96p
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is a cscope interface for (X)Emacs for dealing with Python code. It
;; uses pycscope.py to create the cscope database instead of cscope itself so
;; that only Python source files are indexed. It currently runs under Unix
;; only. Then the regular cscope utility is invoked.
;;
;; Using cscope, you can easily search for where symbols are used and defined.
;; Cscope is designed to answer questions like:
;;
;;         Where is this variable used?
;;         What is the value of this preprocessor symbol?
;;         Where is this function in the source files?
;;         What functions call this function?
;;         What functions are called by this function?
;;         Where does the message "out of space" come from?
;;         Where is this source file in the directory structure?
;;         What files include this header file?
;;
;; Send comments to one of:     darrylo@soco.agilent.com
;;                              darryl_okahata@agilent.com
;;                              darrylo@sonic.net
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ***** INSTALLATION *****
;;
;; * NOTE: this interface currently runs under Unix only.
;;
;; This module needs a shell script called "pycscope-indexer", which
;; should have been supplied along with this emacs-lisp file.  The
;; purpose of "pycscope-indexer" is to create and optionally maintain
;; the pycscope databases.  If all of your source files are in one
;; directory, you don't need this script; it's very nice to have,
;; though, as it handles recursive subdirectory indexing, and can be
;; used in a nightly or weekly cron job to index very large source
;; repositories.  See the beginning of the file, "pycscope-indexer", for
;; usage information.
;;
;; Installation steps:
;;
;; 0. (It is, of course, assumed that pycscope is already properly
;;    installed on the current system.)
;;
;; 1. Install the "pycscope-indexer" script into some convenient
;;    directory in $PATH.  The only real constraint is that (X)Emacs
;;    must be able to find and execute it.  You may also have to edit
;;    the value of PATH in the script, although this is unlikely; the
;;    majority of people should be able to use the script, "as-is".
;;
;; 2. Make sure that the "pycscope-indexer" script is executable.  In
;;    particular, if you had to ftp this file, it is probably no
;;    longer executable.
;;
;; 3. Put this emacs-lisp file somewhere where (X)Emacs can find it.  It
;;    basically has to be in some directory listed in "load-path".
;;
;; 4. Edit your ~/.emacs file to add the line:
;;
;;      (require 'xpycscope)
;;
;; 5. If you intend to use xpycscope.el often you can optionally edit your
;;    ~/.emacs file to add keybindings that reduce the number of keystrokes
;;    required.  For example, the following will add "C-f#" keybindings, which
;;    are easier to type than the usual "C-c s" prefixed keybindings.  Note
;;    that specifying "global-map" instead of "pycscope:map" makes the
;;    keybindings available in all buffers:
;;
;;	(define-key global-map [(control f3)]  'pycscope-set-initial-directory)
;;	(define-key global-map [(control f4)]  'pycscope-unset-initial-directory)
;;	(define-key global-map [(control f5)]  'pycscope-find-this-symbol)
;;	(define-key global-map [(control f6)]  'pycscope-find-global-definition)
;;	(define-key global-map [(control f7)]
;;	  'pycscope-find-global-definition-no-prompting)
;;	(define-key global-map [(control f8)]  'pycscope-pop-mark)
;;	(define-key global-map [(control f9)]  'pycscope-next-symbol)
;;	(define-key global-map [(control f10)] 'pycscope-next-file)
;;	(define-key global-map [(control f11)] 'pycscope-prev-symbol)
;;	(define-key global-map [(control f12)] 'pycscope-prev-file)
;;      (define-key global-map [(meta f9)]  'pycscope-display-buffer)
;;      (defin-ekey global-map [(meta f10)] 'pycscope-display-buffer-toggle)
;;
;; 6. Restart (X)Emacs.  That's it.
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ***** USING THIS MODULE *****
;;
;; * Basic usage:
;;
;; If all of your Python source files are in the same directory, you can just
;; start using this module.  If your files are spread out over multiple
;; directories, see "Advanced usage", below.
;;
;; Just edit a source file, and use the pull-down or pop-up (button 3)
;; menus to select one of:
;;
;;         Find symbol
;;         Find global definition
;;         Find called functions
;;         Find functions calling a function
;;         Find text string
;;         Find egrep pattern
;;         Find a file
;;         Find files #including a file
;;
;; The pycscope database will be automatically created in the same
;; directory as the source files (assuming that you've never used
;; pycscope before), and a buffer will pop-up displaying the results.
;; You can then use button 2 (the middle button) on the mouse to edit
;; the selected file, or you can move the text cursor over a selection
;; and press [Enter].
;;
;; Hopefully, the interface should be fairly intuitive.
;;
;;
;; * Locating the pycscope databases:
;;
;; This module will first use the variable, `pycscope-database-regexps',
;; to search for a suitable database directory.  If a database location
;; cannot be found using this variable then a search is begun at the
;; variable, `pycscope-initial-directory', if set, or the current
;; directory otherwise.  If the directory is not a pycscope database
;; directory then the directory's parent, parent's parent, etc. is
;; searched until a pycscope database directory is found, or the root
;; directory is reached.  If the root directory is reached, the current
;; directory will be used.
;;
;; A pycscope database directory is one in which EITHER a pycscope database
;; file (e.g., "pycscope.out") OR a pycscope file list (e.g.,
;; "pycscope.files") exists.  If only "pycscope.files" exists, the
;; corresponding "pycscope.out" will be automatically created by pycscope
;; when a search is done.  By default, the pycscope database file is called
;; "pycscope.out", but this can be changed (on a global basis) via the
;; variable, `pycscope-database-file'.  There is limited support for pycscope
;; databases that are named differently than that given by
;; `pycscope-database-file', using the variable, `pycscope-database-regexps'.
;;
;; Note that the variable, `pycscope-database-regexps', is generally not
;; needed, as the normal hierarchical database search is sufficient
;; for placing and/or locating the pycscope databases.  However, there
;; may be cases where it makes sense to place the pycscope databases
;; away from where the source files are kept; in this case, this
;; variable is used to determine the mapping.  One use for this
;; variable is when you want to share the database file with other
;; users; in this case, the database may be located in a directory
;; separate from the source files.
;;
;; Setting the variable, `pycscope-initial-directory', is useful when a
;; search is to be expanded by specifying a pycscope database directory
;; that is a parent of the directory that this module would otherwise
;; use.  For example, consider a project that contains the following
;; pycscope database directories:
;;
;;     /users/jdoe/sources
;;     /users/jdoe/sources/proj1
;;     /users/jdoe/sources/proj2
;;
;; If a search is initiated from a .py file in /users/jdoe/sources/proj1
;; then (assuming the variable, `pycscope-database-regexps', is not set)
;; /users/jdoe/sources/proj1 will be used as the pycscope data base directory.
;; Only matches in files in /users/jdoe/sources/proj1 will be found.  This
;; can be remedied by typing "C-c s a" and then "M-del" to remove single
;; path element in order to use a pycscope database directory of
;; /users/jdoe/sources.  Normal searching can be restored by typing "C-c s A".
;;
;;
;; * Keybindings:
;;
;; All keybindings use the "C-c s" prefix, but are usable only while
;; editing a source file, or in the cscope results buffer:
;;
;;      C-c s s         Find symbol.
;;      C-c s d         Find global definition.
;;      C-c s g         Find global definition (alternate binding).
;;      C-c s G         Find global definition without prompting.
;;      C-c s c         Find functions calling a function.
;;      C-c s C         Find called functions (list functions called
;;                      from a function).
;;      C-c s t         Find text string.
;;      C-c s e         Find egrep pattern.
;;      C-c s f         Find a file.
;;      C-c s i         Find files #including a file.
;;      C-c s j         Find assignment to symbol.
;;
;; These pertain to navigation through the search results:
;;
;;      C-c s b         Display *pycscope* buffer.
;;      C-c s B         Auto display *pycscope* buffer toggle.
;;      C-c s n         Next symbol.
;;      C-c s N         Next file.
;;      C-c s p         Previous symbol.
;;      C-c s P         Previous file.
;;      C-c s u         Pop mark.
;;
;; These pertain to setting and unsetting the variable,
;; `pycscope-initial-directory', (location searched for the pycscope database
;;  directory):
;;
;;      C-c s a         Set initial directory.
;;      C-c s A         Unset initial directory.
;;
;; These pertain to pycscope database maintenance:
;;
;;      C-c s L         Create list of files to index.
;;      C-c s I         Create list and index.
;;      C-c s O         Create index.
;;      C-c s E         Edit list of files to index.
;;      C-c s W         Locate this buffer's pycscope directory
;;                      ("W" --> "where").
;;      C-c s S         Locate this buffer's pycscope directory.
;;                      (alternate binding: "S" --> "show").
;;      C-c s T         Locate this buffer's pycscope directory.
;;                      (alternate binding: "T" --> "tell").
;;      C-c s D         Dired this buffer's directory.
;;
;;
;; * Advanced usage:
;;
;; If the source files are spread out over multiple directories,
;; you've got a few choices:
;;
;; [ NOTE: you will need to have the script, "pycscope-indexer",
;;   properly installed in order for the following to work.  ]
;;
;; 1. If all of the directories exist below a common directory
;;    (without any extraneous, unrelated subdirectories), you can tell
;;    this module to place the pycscope database into the top-level,
;;    common directory.  This assumes that you do not have any pycscope
;;    databases in any of the subdirectories.  If you do, you should
;;    delete them; otherwise, they will take precedence over the
;;    top-level database.
;;
;;    If you do have pycscope databases in any subdirectory, the
;;    following instructions may not work right.
;;
;;    It's pretty easy to tell this module to use a top-level, common
;;    directory:
;;
;;    a. Make sure that the menu pick, "PyCscope/Index recursively", is
;;       checked (the default value).
;;
;;    b. Select the menu pick, "PyCscope/Create list and index", and
;;       specify the top-level directory.  This will run the script,
;;       "pycscope-indexer", in the background, so you can do other
;;       things if indexing takes a long time.  A list of files to
;;       index will be created in "pycscope.files", and the pycscope
;;       database will be created in "pycscope.out".
;;
;;    Once this has been done, you can then use the menu picks
;;    (described in "Basic usage", above) to search for symbols.
;;
;;    Note, however, that, if you add or delete source files, you'll
;;    have to either rebuild the database using the above procedure,
;;    or edit the file, "pycscope.files" to add/delete the names of the
;;    source files.  To edit this file, you can use the menu pick,
;;    "PyCscope/Edit list of files to index".
;;
;;
;; 2. If most of the files exist below a common directory, but a few
;;    are outside, you can use the menu pick, "PyCscope/Create list of
;;    files to index", and specify the top-level directory.  Make sure
;;    that "PyCscope/Index recursively", is checked before you do so,
;;    though.  You can then edit the list of files to index using the
;;    menu pick, "PyCscope/Edit list of files to index".  Just edit the
;;    list to include any additional source files not already listed.
;;
;;    Once you've created, edited, and saved the list, you can then
;;    use the menu picks described under "Basic usage", above, to
;;    search for symbols.  The first time you search, you will have to
;;    wait a while for pycscope to fully index the source files, though.
;;    If you have a lot of source files, you may want to manually run
;;    pycscope to build the database:
;;
;;            cd top-level-directory    # or wherever
;;            rm -f pycscope.out        # not always necessary
;;            pycscope.py -R -f pycscope.out
;;
;;
;; 3. If the source files are scattered in many different, unrelated
;;    places, you'll have to manually create pycscope.files and put a
;;    list of all pathnames into it.  Then build the database using:
;;
;;            cd some-directory         # wherever pycscope.files exists
;;            rm -f pycscope.out        # not always necessary
;;            pycscope.py -R -f pycscope.out
;;
;;    Next, read the documentation for the variable,
;;    "pycscope-database-regexps", and set it appropriately, such that
;;    the above-created pycscope database will be referenced when you
;;    edit a related source file.
;;
;;    Once this has been done, you can then use the menu picks
;;    described under "Basic usage", above, to search for symbols.
;;
;;
;; * Interesting configuration variables:
;;
;; "pycscope-truncate-lines"
;;      This is the value of `truncate-lines' to use in pycscope
;;      buffers; the default is the current setting of
;;      `truncate-lines'.  This variable exists because it can be
;;      easier to read pycscope buffers with truncated lines, while
;;      other buffers do not have truncated lines.
;;
;; "pycscope-use-relative-paths"
;;      If non-nil, use relative paths when creating the list of files
;;      to index.  The path is relative to the directory in which the
;;      pycscope database will be created.  If nil, absolute paths will
;;      be used.  Absolute paths are good if you plan on moving the
;;      database to some other directory (if you do so, you'll
;;      probably also have to modify `pycscope-database-regexps').
;;      Absolute paths may also be good if you share the database file
;;      with other users (you'll probably want to specify some
;;      automounted network path for this).
;;
;; "pycscope-index-recursively"
;;      If non-nil, index files in the current directory and all
;;      subdirectories.  If nil, only files in the current directory
;;      are indexed.  This variable is only used when creating the
;;      list of files to index, or when creating the list of files and
;;      the corresponding pycscope database.
;;
;; "pycscope-name-line-width"
;;      The width of the combined "function name:line number" field in
;;      the pycscope results buffer.  If negative, the field is
;;      left-justified.
;;
;; "pycscope-do-not-update-database"
;;      If non-nil, never check and/or update the pycscope database when
;;      searching.  Beware of setting this to non-nil, as this will
;;      disable automatic database creation, updating, and
;;      maintenance.
;;
;; "pycscope-display-pycscope-buffer"
;;      If non-nil, display the *pycscope* buffer after each search
;;      (default).  This variable can be set in order to reduce the
;;      number of keystrokes required to navigate through the matches.
;;
;; "pycscope-database-regexps"
;; 	List to force directory-to-pycscope-database mappings.
;; 	This is a list of `(REGEXP DBLIST [ DBLIST ... ])', where:
;;
;; 	REGEXP is a regular expression matched against the current buffer's
;; 	current directory.  The current buffer is typically some source file,
;; 	and you're probably searching for some symbol in or related to this
;; 	file.  Basically, this regexp is used to relate the current directory
;; 	to a pycscope database.  You need to start REGEXP with "^" if you want
;; 	to match from the beginning of the current directory.
;;
;; 	DBLIST is a list that contains one or more of:
;;
;; 	    ( DBDIR )
;; 	    ( DBDIR ( OPTIONS ) )
;; 	    ( t )
;; 	    t
;;
;; 	Here, DBDIR is a directory (or a file) that contains a pycscope
;; 	database.  If DBDIR is a directory, then it is expected that the
;; 	pycscope database, if present, has the filename given by the variable,
;; 	`pycscope-database-file'; if DBDIR is a file, then DBDIR is the path
;; 	name to a pycscope database file (which does not have to be the same as
;; 	that given by `pycscope-database-file').  If only DBDIR is specified,
;; 	then that pycscope database will be searched without any additional
;; 	pycscope command-line options.  If OPTIONS is given, then OPTIONS is a
;; 	list of strings, where each string is a separate pycscope command-line
;; 	option.
;;
;; 	In the case of "( t )", this specifies that the search is to use the
;; 	normal hierarchical database search.  This option is used to
;; 	explicitly search using the hierarchical database search either before
;; 	or after other pycscope database directories.
;;
;; 	If "t" is specified (not inside a list), this tells the searching
;; 	mechanism to stop searching if a match has been found (at the point
;; 	where "t" is encountered).  This is useful for those projects that
;; 	consist of many subprojects.  You can specify the most-used
;; 	subprojects first, followed by a "t", and then followed by a master
;; 	pycscope database directory that covers all subprojects.  This will
;; 	cause the most-used subprojects to be searched first (hopefully
;; 	quickly), and the search will then stop if a match was found.  If not,
;; 	the search will continue using the master pycscope database directory.
;;
;; 	Here, `pycscope-database-regexps' is generally not used, as the normal
;; 	hierarchical database search is sufficient for placing and/or locating
;; 	the pycscope databases.  However, there may be cases where it makes
;; 	sense to place the pycscope databases away from where the source files
;; 	are kept; in this case, this variable is used to determine the
;; 	mapping.
;;
;; 	This module searches for the pycscope databases by first using this
;; 	variable; if a database location cannot be found using this variable,
;; 	then the current directory is searched, then the parent, then the
;; 	parent's parent, until a pycscope database directory is found, or the
;; 	root directory is reached.  If the root directory is reached, the
;; 	current directory will be used.
;;
;; 	A pycscope database directory is one in which EITHER a pycscope database
;; 	file (e.g., "pycscope.out") OR a pycscope file list (e.g.,
;; 	"pycscope.files") exists.  If only "pycscope.files" exists, the
;; 	corresponding "pycscope.out" will be automatically created by pycscope
;; 	when a search is done.  By default, the pycscope database file is called
;; 	"pycscope.out", but this can be changed (on a global basis) via the
;; 	variable, `pycscope-database-file'.  There is limited support for pycscope
;; 	databases that are named differently than that given by
;; 	`pycscope-database-file', using the variable, `pycscope-database-regexps'.
;;
;; 	Here is an example of `pycscope-database-regexps':
;;
;;		(setq pycscope-database-regexps
;;		      '(
;;			( "^/users/jdoe/sources/proj1"
;;			  ( t )
;;			  ( "/users/jdoe/sources/proj2")
;;			  ( "/users/jdoe/sources/proj3/mypycscope.out")
;;			  ( "/users/jdoe/sources/proj4")
;;			  t
;;			  ( "/some/master/directory" ("-R") )
;;			  )
;;			( "^/users/jdoe/sources/gnome/"
;;			  ( "/master/gnome/database" ("-R") )
;;			  )
;;			))
;;
;; 	If the current buffer's directory matches the regexp,
;; 	"^/users/jdoe/sources/proj1", then the following search will be
;; 	done:
;;
;; 	    1. First, the normal hierarchical database search will be used to
;;	       locate a pycscope database.
;;
;; 	    2. Next, searches will be done using the pycscope database
;;	       directories, "/users/jdoe/sources/proj2",
;;	       "/users/jdoe/sources/proj3/mypycscope.out", and
;;	       "/users/jdoe/sources/proj4".  Note that, instead of the file,
;;	       "pycscope.out", the file, "mypycscope.out", will be used in the
;;	       directory "/users/jdoe/sources/proj3".
;;
;; 	    3. If a match was found, searching will stop.
;;
;; 	    4. If a match was not found, searching will be done using
;;	       "/some/master/directory", and the command-line option "-R"
;;	       will be passed to pycscope.
;;
;; 	If the current buffer's directory matches the regexp,
;; 	"^/users/jdoe/sources/gnome", then the following search will be
;; 	done:
;;
;; 	    The search will be done only using the directory,
;; 	    "/master/gnome/database".  The "-R" option will be passed to
;; 	    pycscope.
;;
;; 	If the current buffer's directory does not match any of the above
;; 	regexps, then only the normal hierarchical database search will be
;; 	done.
;;
;;
;; * Other notes:
;;
;; 1. The script, "pycscope-indexer", uses a sed command to determine what is
;;    and is not a .py source file.  It's idea of a source file may not
;;    correspond to yours.
;;
;; 2. This module is called, "xpycscope", in keeping with the original C
;;    version of this module.
;;
;;
;; * KNOWN BUGS:
;;
;; 1. Cannot handle whitespace in directory or file names.
;;
;; 2. By default, colored faces are used to display results.  If you happen
;;    to use a black background, part of the results may be invisible
;;    (because the foreground color may be black, too).  There are at least
;;    two solutions for this:
;;
;;    2a. Turn off colored faces, by setting `pycscope-use-face' to `nil',
;;        e.g.:
;;
;;            (setq pycscope-use-face nil)
;;
;;    2b. Explicitly set colors for the faces used by pycscope.  The faces
;;        are:
;;
;;            pycscope-file-face
;;            pycscope-function-face
;;            pycscope-line-number-face
;;            pycscope-line-face
;;            pycscope-mouse-face
;;
;;        The face most likely to cause problems (e.g., black-on-black
;;        color) is `pycscope-line-face'.
;;
;; 3. The support for pycscope databases different from that specified by
;;    `pycscope-database-file' is quirky.  If the file does not exist, it
;;    will not be auto-created (unlike files names by
;;    `pycscope-database-file').  You can manually force the file to be
;;    created by using touch(1) to create a zero-length file; the
;;    database will be created the next time a search is done.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'easymenu)


(defgroup pycscope nil
  "PyCscope interface for (X)Emacs.
Using cscope, you can easily search for where symbols are used and defined.
It is designed to answer questions like:

        Where is this variable used?
        What is the value of this preprocessor symbol?
        Where is this function in the source files?
        What functions call this function?
        What functions are called by this function?
        Where does the message \"out of space\" come from?
        Where is this source file in the directory structure?
        What files include this header file?
"
  :prefix "pycscope-"
  :group 'tools)


(defcustom pycscope-do-not-update-database t
  "*If non-nil, never check and/or update the pycscope database when searching.
Beware of setting this to non-nil, as this will disable automatic database
creation, updating, and maintenance."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-database-regexps nil
  "*List to force directory-to-pycscope-database mappings.
This is a list of `(REGEXP DBLIST [ DBLIST ... ])', where:

REGEXP is a regular expression matched against the current buffer's
current directory.  The current buffer is typically some source file,
and you're probably searching for some symbol in or related to this
file.  Basically, this regexp is used to relate the current directory
to a pycscope database.  You need to start REGEXP with \"^\" if you want
to match from the beginning of the current directory.

DBLIST is a list that contains one or more of:

    ( DBDIR )
    ( DBDIR ( OPTIONS ) )
    ( t )
    t

Here, DBDIR is a directory (or a file) that contains a pycscope database.
If DBDIR is a directory, then it is expected that the pycscope database,
if present, has the filename given by the variable,
`pycscope-database-file'; if DBDIR is a file, then DBDIR is the path name
to a pycscope database file (which does not have to be the same as that
given by `pycscope-database-file').  If only DBDIR is specified, then that
pycscope database will be searched without any additional pycscope
command-line options.  If OPTIONS is given, then OPTIONS is a list of
strings, where each string is a separate pycscope command-line option.

In the case of \"( t )\", this specifies that the search is to use the
normal hierarchical database search.  This option is used to
explicitly search using the hierarchical database search either before
or after other pycscope database directories.

If \"t\" is specified (not inside a list), this tells the searching
mechanism to stop searching if a match has been found (at the point
where \"t\" is encountered).  This is useful for those projects that
consist of many subprojects.  You can specify the most-used
subprojects first, followed by a \"t\", and then followed by a master
pycscope database directory that covers all subprojects.  This will
cause the most-used subprojects to be searched first (hopefully
quickly), and the search will then stop if a match was found.  If not,
the search will continue using the master pycscope database directory.

Here, `pycscope-database-regexps' is generally not used, as the normal
hierarchical database search is sufficient for placing and/or locating
the pycscope databases.  However, there may be cases where it makes
sense to place the pycscope databases away from where the source files
are kept; in this case, this variable is used to determine the
mapping.

This module searches for the pycscope databases by first using this
variable; if a database location cannot be found using this variable,
then the current directory is searched, then the parent, then the
parent's parent, until a pycscope database directory is found, or the
root directory is reached.  If the root directory is reached, the
current directory will be used.

A pycscope database directory is one in which EITHER a pycscope database
file (e.g., \"pycscope.out\") OR a pycscope file list (e.g.,
\"pycscope.files\") exists.  If only \"pycscope.files\" exists, the
corresponding \"pycscope.out\" will be automatically created by pycscope
when a search is done.  By default, the pycscope database file is called
\"pycscope.out\", but this can be changed (on a global basis) via the
variable, `pycscope-database-file'.  There is limited support for pycscope
databases that are named differently than that given by
`pycscope-database-file', using the variable, `pycscope-database-regexps'.

Here is an example of `pycscope-database-regexps':

        (setq pycscope-database-regexps
              '(
                ( \"^/users/jdoe/sources/proj1\"
                  ( t )
                  ( \"/users/jdoe/sources/proj2\")
                  ( \"/users/jdoe/sources/proj3/mypycscope.out\")
                  ( \"/users/jdoe/sources/proj4\")
                  t
                  ( \"/some/master/directory\" (\"-R\") )
                  )
                ( \"^/users/jdoe/sources/gnome/\"
                  ( \"/master/gnome/database\" (\"-R\") )
                  )
                ))

If the current buffer's directory matches the regexp,
\"^/users/jdoe/sources/proj1\", then the following search will be
done:

    1. First, the normal hierarchical database search will be used to
       locate a pycscope database.

    2. Next, searches will be done using the pycscope database
       directories, \"/users/jdoe/sources/proj2\",
       \"/users/jdoe/sources/proj3/mypycscope.out\", and
       \"/users/jdoe/sources/proj4\".  Note that, instead of the file,
       \"pycscope.out\", the file, \"mypycscope.out\", will be used in the
       directory \"/users/jdoe/sources/proj3\".

    3. If a match was found, searching will stop.

    4. If a match was not found, searching will be done using
       \"/some/master/directory\", and the command-line option \"-R\"
       will be passed to pycscope.

If the current buffer's directory matches the regexp,
\"^/users/jdoe/sources/gnome\", then the following search will be
done:

    The search will be done only using the directory,
    \"/master/gnome/database\".  The \"-R\" option will be passed to
    pycscope.

If the current buffer's directory does not match any of the above
regexps, then only the normal hierarchical database search will be
done.

"
  :type '(repeat (list :format "%v"
		       (choice :value ""
			       (regexp :tag "Buffer regexp")
			       string)
		       (choice :value ""
			       (directory :tag "PyCscope database directory")
			       string)
		       (string :value ""
			       :tag "Optional pycscope command-line arguments")
		       ))
  :group 'pycscope)
(defcustom pycscope-name-line-width -30
  "*The width of the combined \"function name:line number\" field in the
pycscope results buffer.  If negative, the field is left-justified."
  :type 'integer
  :group 'pycscope)


(defcustom pycscope-truncate-lines truncate-lines
  "*The value of `truncate-lines' to use in pycscope buffers.
This variable exists because it can be easier to read pycscope buffers
with truncated lines, while other buffers do not have truncated lines."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-display-times t
  "*If non-nil, display how long each search took.
The elasped times are in seconds.  Floating-point support is required
for this to work."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-program "cscope"
  "*The pathname of the cscope executable to use."
  :type 'string
  :group 'pycscope)


(defcustom pycscope-index-file "pycscope.files"
  "*The name of the pycscope file list file."
  :type 'string
  :group 'pycscope)


(defcustom pycscope-database-file "pycscope.out"
  "*The name of the pycscope database file."
  :type 'string
  :group 'pycscope)


(defcustom pycscope-edit-single-match t
  "*If non-nil and only one match is output, edit the matched location."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-display-pycscope-buffer t
  "*If non-nil automatically display the *pycscope* buffer after each search."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-stop-at-first-match-dir nil
  "*If non-nil, stop searching through multiple databases if a match is found.
This option is useful only if multiple pycscope database directories are being
used.  When multiple databases are searched, setting this variable to non-nil
will cause searches to stop when a search outputs anything; no databases after
this one will be searched."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-use-relative-paths t
  "*If non-nil, use relative paths when creating the list of files to index.
The path is relative to the directory in which the pycscope database
will be created.  If nil, absolute paths will be used.  Absolute paths
are good if you plan on moving the database to some other directory
(if you do so, you'll probably also have to modify
\`pycscope-database-regexps\').  Absolute paths  may also be good if you
share the database file with other users (you\'ll probably want to
specify some automounted network path for this)."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-index-recursively t
  "*If non-nil, index files in the current directory and all subdirectories.
If nil, only files in the current directory are indexed.  This
variable is only used when creating the list of files to index, or
when creating the list of files and the corresponding pycscope database."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-no-mouse-prompts nil
  "*If non-nil, use the symbol under the cursor instead of prompting.
Do not prompt for a value, except for when seaching for a egrep pattern
or a file."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-suppress-empty-matches t
  "*If non-nil, delete empty matches.")


(defcustom pycscope-indexing-script "pycscope-indexer"
  "*The shell script used to create pycscope indices."
  :type 'string
  :group 'pycscope)


(defcustom pycscope-symbol-chars "A-Za-z0-9_"
  "*A string containing legal characters in a symbol.
The current syntax table should really be used for this."
  :type 'string
  :group 'pycscope)


(defcustom pycscope-filename-chars "-.,/A-Za-z0-9_~!@#$%&+=\\\\"
  "*A string containing legal characters in a symbol.
The current syntax table should really be used for this."
  :type 'string
  :group 'pycscope)


(defcustom pycscope-allow-arrow-overlays t
  "*If non-nil, use an arrow overlay to show target lines.
Arrow overlays are only used when the following functions are used:

    pycscope-show-entry-other-window
    pycscope-show-next-entry-other-window
    pycscope-show-prev-entry-other-window

The arrow overlay is removed when other pycscope functions are used.
Note that the arrow overlay is not an actual part of the text, and can
be removed by quitting the pycscope buffer."
  :type 'boolean
  :group 'pycscope)


(defcustom pycscope-overlay-arrow-string "=>"
  "*The overlay string to use when displaying arrow overlays."
  :type 'string
  :group 'pycscope)


(defvar pycscope-minor-mode-hooks nil
  "List of hooks to call when entering pycscope-minor-mode.")


(defconst pycscope-separator-line
  "-------------------------------------------------------------------------------\n"
  "Line of text to use as a visual separator.
Must end with a newline.")


;;;;
;;;; Faces for fontification
;;;;

(defcustom pycscope-use-face t
  "*Whether to use text highlighting (à la font-lock) or not."
  :group 'pycscope
  :type '(boolean))


(defface pycscope-file-face
  '((((class color) (background dark))
     (:foreground "yellow"))
    (((class color) (background light))
     (:foreground "blue"))
    (t (:bold t)))
  "Face used to highlight file name in the *pycscope* buffer."
  :group 'pycscope)


(defface pycscope-function-face
  '((((class color) (background dark))
     (:foreground "cyan"))
    (((class color) (background light))
     (:foreground "magenta"))
    (t (:bold t)))
  "Face used to highlight function name in the *pycscope* buffer."
  :group 'pycscope)


(defface pycscope-line-number-face
  '((((class color) (background dark))
     (:foreground "red"))
    (((class color) (background light))
     (:foreground "red"))
    (t (:bold t)))
  "Face used to highlight line number in the *pycscope* buffer."
  :group 'pycscope)


(defface pycscope-line-face
  '((((class color) (background dark))
     (:foreground "green"))
    (((class color) (background light))
     (:foreground "black"))
    (t (:bold nil)))
  "Face used to highlight the rest of line in the *pycscope* buffer."
  :group 'pycscope)


(defface pycscope-mouse-face
  '((((class color) (background dark))
     (:foreground "white" :background "blue"))
    (((class color) (background light))
     (:foreground "white" :background "blue"))
    (t (:bold nil)))
  "Face used when mouse pointer is within the region of an entry."
  :group 'pycscope)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Probably, nothing user-customizable past this point.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defconst pycscope-running-in-xemacs (string-match "XEmacs\\|Lucid" emacs-version))

(defvar pycscope-list-entry-keymap nil
  "The keymap used in the *pycscope* buffer which lists search results.")
(if pycscope-list-entry-keymap
    nil
  (setq pycscope-list-entry-keymap (make-keymap))
  (suppress-keymap pycscope-list-entry-keymap)
  ;; The following section does not appear in the "PyCscope" menu.
  (if pycscope-running-in-xemacs
      (define-key pycscope-list-entry-keymap [button2] 'pycscope-mouse-select-entry-other-window)
    (define-key pycscope-list-entry-keymap [mouse-2] 'pycscope-mouse-select-entry-other-window))
  (define-key pycscope-list-entry-keymap [return] 'pycscope-select-entry-other-window)
  (define-key pycscope-list-entry-keymap " " 'pycscope-show-entry-other-window)
  (define-key pycscope-list-entry-keymap "o" 'pycscope-select-entry-one-window)
  (define-key pycscope-list-entry-keymap "q" 'pycscope-bury-buffer)
  (define-key pycscope-list-entry-keymap "Q" 'pycscope-quit)
  (define-key pycscope-list-entry-keymap "h" 'pycscope-help)
  (define-key pycscope-list-entry-keymap "?" 'pycscope-help)
  ;; The following line corresponds to be beginning of the "PyCscope" menu.
  (define-key pycscope-list-entry-keymap "s" 'pycscope-find-this-symbol)
  (define-key pycscope-list-entry-keymap "d" 'pycscope-find-this-symbol)
  (define-key pycscope-list-entry-keymap "g" 'pycscope-find-global-definition)
  (define-key pycscope-list-entry-keymap "G"
    'pycscope-find-global-definition-no-prompting)
  (define-key pycscope-list-entry-keymap "c" 'pycscope-find-functions-calling-this-function)
  (define-key pycscope-list-entry-keymap "C" 'pycscope-find-called-functions)
  (define-key pycscope-list-entry-keymap "t" 'pycscope-find-this-text-string)
  (define-key pycscope-list-entry-keymap "e" 'pycscope-find-egrep-pattern)
  (define-key pycscope-list-entry-keymap "f" 'pycscope-find-this-file)
  (define-key pycscope-list-entry-keymap "i" 'pycscope-find-files-including-file)
  (define-key pycscope-list-entry-keymap "j" 'pycscope-find-assignments-to-symbol)
  ;; --- (The '---' indicates that this line corresponds to a menu separator.)
  (define-key pycscope-list-entry-keymap "n" 'pycscope-next-symbol)
  (define-key pycscope-list-entry-keymap "N" 'pycscope-next-file)
  (define-key pycscope-list-entry-keymap "p" 'pycscope-prev-symbol)
  (define-key pycscope-list-entry-keymap "P" 'pycscope-prev-file)
  (define-key pycscope-list-entry-keymap "u" 'pycscope-pop-mark)
  ;; ---
  (define-key pycscope-list-entry-keymap "a" 'pycscope-set-initial-directory)
  (define-key pycscope-list-entry-keymap "A" 'pycscope-unset-initial-directory)
  ;; ---
  (define-key pycscope-list-entry-keymap "L" 'pycscope-create-list-of-files-to-index)
  (define-key pycscope-list-entry-keymap "I" 'pycscope-index-files)
  (define-key pycscope-list-entry-keymap "O" 'pycscope-index-files-only)
  (define-key pycscope-list-entry-keymap "E" 'pycscope-edit-list-of-files-to-index)
  (define-key pycscope-list-entry-keymap "W" 'pycscope-tell-user-about-directory)
  (define-key pycscope-list-entry-keymap "S" 'pycscope-tell-user-about-directory)
  (define-key pycscope-list-entry-keymap "T" 'pycscope-tell-user-about-directory)
  (define-key pycscope-list-entry-keymap "D" 'pycscope-dired-directory)
  ;; The previous line corresponds to be end of the "PyCscope" menu.
  )


(defvar pycscope-list-entry-hook nil
  "*Hook run after pycscope-list-entry-mode entered.")


(defun pycscope-list-entry-mode ()
  "Major mode for jumping/showing entry from the list in the *pycscope* buffer.

\\{pycscope-list-entry-keymap}"
  (use-local-map pycscope-list-entry-keymap)
  (setq buffer-read-only t
	mode-name "pycscope"
	major-mode 'pycscope-list-entry-mode
	overlay-arrow-string pycscope-overlay-arrow-string)
  (or overlay-arrow-position
      (setq overlay-arrow-position (make-marker)))
  (run-hooks 'pycscope-list-entry-hook))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar pycscope-output-buffer-name "*pycscope*"
  "The name of the pycscope output buffer.")


(defvar pycscope-info-buffer-name "*pycscope-info*"
  "The name of the pycscope information buffer.")


(defvar pycscope-process nil
  "The current pycscope process.")
(make-variable-buffer-local 'pycscope-process)


(defvar pycscope-process-output nil
  "A buffer for holding partial pycscope process output.")
(make-variable-buffer-local 'pycscope-process-output)


(defvar pycscope-command-args nil
  "Internal variable for holding major command args to pass to pycscope.")
(make-variable-buffer-local 'pycscope-command-args)


(defvar pycscope-start-directory nil
  "Internal variable used to save the initial start directory.
The results buffer gets reset to this directory when a search has
completely finished.")
(make-variable-buffer-local 'pycscope-start-directory)


(defvar pycscope-search-list nil
  "A list of (DIR . FLAGS) entries.
This is a list of database directories to search.  Each entry in the list
is a (DIR . FLAGS) cell.  DIR is the directory to search, and FLAGS are the
flags to pass to cscope when using this database directory.  FLAGS can be
nil (meaning, \"no flags\").")
(make-variable-buffer-local 'pycscope-search-list)


(defvar pycscope-searched-dirs nil
  "The list of database directories already searched.")
(make-variable-buffer-local 'pycscope-searched-dirs)


(defvar pycscope-filter-func nil
  "Internal variable for holding the filter function to use (if any) when
searching.")
(make-variable-buffer-local 'pycscope-filter-func)


(defvar pycscope-sentinel-func nil
  "Internal variable for holding the sentinel function to use (if any) when
searching.")
(make-variable-buffer-local 'pycscope-filter-func)


(defvar pycscope-last-file nil
  "The file referenced by the last line of cscope process output.")
(make-variable-buffer-local 'pycscope-last-file)


(defvar pycscope-start-time nil
  "The search start time, in seconds.")
(make-variable-buffer-local 'pycscope-start-time)


(defvar pycscope-first-match nil
  "The first match result output by cscope.")
(make-variable-buffer-local 'pycscope-first-match)


(defvar pycscope-first-match-point nil
  "Buffer location of the first match.")
(make-variable-buffer-local 'pycscope-first-match-point)


(defvar pycscope-item-start nil
  "The point location of the start of a search's output, before header info.")
(make-variable-buffer-local 'pycscope-output-start)


(defvar pycscope-output-start nil
  "The point location of the start of a search's output.")
(make-variable-buffer-local 'pycscope-output-start)


(defvar pycscope-matched-multiple nil
  "Non-nil if cscope output multiple matches.")
(make-variable-buffer-local 'pycscope-matched-multiple)


(defvar pycscope-stop-at-first-match-dir-meta nil
  "")
(make-variable-buffer-local 'pycscope-stop-at-first-match-dir-meta)


(defvar pycscope-symbol nil
  "The last symbol searched for.")


(defvar pycscope-adjust t
  "True if the symbol searched for (pycscope-symbol) should be on
the line specified by the pycscope database.  In such cases the point will be
adjusted if need be (fuzzy matching).")


(defvar pycscope-adjust-range 1000
  "How far the point should be adjusted if the symbol is not on the line
specified by the pycscope database.")


(defvar pycscope-marker nil
  "The location from which cscope was invoked.")


(defvar pycscope-marker-window nil
  "The window which should contain pycscope-marker.  This is the window from
which pycscope-marker is set when searches are launched from the *pycscope*
buffer.")


(defvar pycscope-marker-ring-length 16
  "Length of the pycscope marker ring.")


(defvar pycscope-marker-ring (make-ring pycscope-marker-ring-length)
  "Ring of markers which are locations from which pycscope was invoked.")


(defvar pycscope-initial-directory nil
  "When set the directory in which searches for the pycscope database
directory should begin.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar pycscope:map nil
  "The pycscope keymap.")
(if pycscope:map
    nil
  (setq pycscope:map (make-sparse-keymap))
  ;; The following line corresponds to be beginning of the "PyCscope" menu.
  (define-key pycscope:map "\C-css" 'pycscope-find-this-symbol)
  (define-key pycscope:map "\C-csd" 'pycscope-find-global-definition)
  (define-key pycscope:map "\C-csg" 'pycscope-find-global-definition)
  (define-key pycscope:map "\C-csG" 'pycscope-find-global-definition-no-prompting)
  (define-key pycscope:map "\C-csc" 'pycscope-find-functions-calling-this-function)
  (define-key pycscope:map "\C-csC" 'pycscope-find-called-functions)
  (define-key pycscope:map "\C-cst" 'pycscope-find-this-text-string)
  (define-key pycscope:map "\C-cse" 'pycscope-find-egrep-pattern)
  (define-key pycscope:map "\C-csf" 'pycscope-find-this-file)
  (define-key pycscope:map "\C-csi" 'pycscope-find-files-including-file)
  (define-key pycscope:map "\C-csj" 'pycscope-find-assignments-to-symbol)
  ;; --- (The '---' indicates that this line corresponds to a menu separator.)
  (define-key pycscope:map "\C-csb" 'pycscope-display-buffer)
  (define-key pycscope:map "\C-csB" 'pycscope-display-buffer-toggle)
  (define-key pycscope:map "\C-csn" 'pycscope-next-symbol)
  (define-key pycscope:map "\C-csN" 'pycscope-next-file)
  (define-key pycscope:map "\C-csp" 'pycscope-prev-symbol)
  (define-key pycscope:map "\C-csP" 'pycscope-prev-file)
  (define-key pycscope:map "\C-csu" 'pycscope-pop-mark)
  ;; ---
  (define-key pycscope:map "\C-csa" 'pycscope-set-initial-directory)
  (define-key pycscope:map "\C-csA" 'pycscope-unset-initial-directory)
  ;; ---
  (define-key pycscope:map "\C-csL" 'pycscope-create-list-of-files-to-index)
  (define-key pycscope:map "\C-csI" 'pycscope-index-files)
  (define-key pycscope:map "\C-csO" 'pycscope-index-files-only)
  (define-key pycscope:map "\C-csE" 'pycscope-edit-list-of-files-to-index)
  (define-key pycscope:map "\C-csW" 'pycscope-tell-user-about-directory)
  (define-key pycscope:map "\C-csS" 'pycscope-tell-user-about-directory)
  (define-key pycscope:map "\C-csT" 'pycscope-tell-user-about-directory)
  (define-key pycscope:map "\C-csD" 'pycscope-dired-directory))
  ;; The previous line corresponds to be end of the "PyCscope" menu.

(easy-menu-define pycscope:menu
		  (list pycscope:map pycscope-list-entry-keymap)
		  "pycscope menu"
		  '("PyCscope"
		    [ "Find symbol" pycscope-find-this-symbol t ]
		    [ "Find global definition" pycscope-find-global-definition t ]
		    [ "Find global definition no prompting"
		      pycscope-find-global-definition-no-prompting t ]
		    [ "Find functions calling a function"
		      pycscope-find-functions-calling-this-function t ]
		    [ "Find called functions" pycscope-find-called-functions t ]
		    [ "Find text string" pycscope-find-this-text-string t ]
		    [ "Find egrep pattern" pycscope-find-egrep-pattern t ]
		    [ "Find a file" pycscope-find-this-file t ]
		    [ "Find files #including a file"
		      pycscope-find-files-including-file t ]
		    [ "Find assignments to symbol"
		      pycscope-find-assignments-to-symbol t ]
		    "-----------"
		    [ "Display *pycscope* buffer" pycscope-display-buffer t ]
		    [ "Auto display *pycscope* buffer toggle"
		      pycscope-display-buffer-toggle t ]
		    [ "Next symbol"     	pycscope-next-symbol t ]
		    [ "Next file"       	pycscope-next-file t ]
		    [ "Previous symbol" 	pycscope-prev-symbol t ]
		    [ "Previous file"   	pycscope-prev-file t ]
		    [ "Pop mark"        	pycscope-pop-mark t ]
		    "-----------"
		    ( "PyCscope Database"
		      [ "Set initial directory"
			pycscope-set-initial-directory t ]
		      [ "Unset initial directory"
			pycscope-unset-initial-directory t ]
		      "-----------"
		      [ "Create list of files to index"
			pycscope-create-list-of-files-to-index t ]
		      [ "Create list and index"
			pycscope-index-files t ]
		      [ "Create index"
			pycscope-index-files-only t ]
		      [ "Edit list of files to index"
			pycscope-edit-list-of-files-to-index t ]
		      [ "Locate this buffer's pycscope directory"
			pycscope-tell-user-about-directory t ]
		      [ "Dired this buffer's pycscope directory"
			pycscope-dired-directory t ]
		      )
		    "-----------"
		    ( "Options"
		      [ "Auto edit single match"
			(setq pycscope-edit-single-match
			      (not pycscope-edit-single-match))
			:style toggle :selected pycscope-edit-single-match ]
		      [ "Auto display *pycscope* buffer"
			(setq pycscope-display-pycscope-buffer
			      (not pycscope-display-pycscope-buffer))
			:style toggle :selected pycscope-display-pycscope-buffer ]
		      [ "Stop at first matching database"
			(setq pycscope-stop-at-first-match-dir
			      (not pycscope-stop-at-first-match-dir))
			:style toggle
			:selected pycscope-stop-at-first-match-dir ]
		      [ "Never update pycscope database"
			(setq pycscope-do-not-update-database
			      (not pycscope-do-not-update-database))
			:style toggle :selected pycscope-do-not-update-database ]
		      [ "Index recursively"
			(setq pycscope-index-recursively
			      (not pycscope-index-recursively))
			:style toggle :selected pycscope-index-recursively ]
		      [ "Suppress empty matches"
			(setq pycscope-suppress-empty-matches
			      (not pycscope-suppress-empty-matches))
			:style toggle :selected pycscope-suppress-empty-matches ]
		      [ "Use relative paths"
			(setq pycscope-use-relative-paths
			      (not pycscope-use-relative-paths))
			:style toggle :selected pycscope-use-relative-paths ]
		      [ "No mouse prompts" (setq pycscope-no-mouse-prompts
						 (not pycscope-no-mouse-prompts))
			:style toggle :selected pycscope-no-mouse-prompts ]
		      )
		    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Internal functions and variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar pycscope-common-text-plist
  (let (plist)
    (setq plist (plist-put plist 'mouse-face 'pycscope-mouse-face))
    plist)
  "List of common text properties to be added to the entry line.")


(defun pycscope-insert-with-text-properties (text filename &optional line-number)
  "Insert an entry with given TEXT, add entry attributes as text properties.
The text properties to be added:
- common property: mouse-face,
- properties are used to open target file and its location: pycscope-file,
  pycscope-line-number"
  (let ((plist pycscope-common-text-plist)
	beg end)
    (setq beg (point))
    (insert text)
    (setq end (point)
	  plist (plist-put plist 'pycscope-file filename))
    (if line-number
	(progn
	  (if (stringp line-number)
	      (setq line-number (string-to-number line-number)))
	  (setq plist (plist-put plist 'pycscope-line-number line-number))
	  ))
    (add-text-properties beg end plist)
    ))


(if pycscope-running-in-xemacs
    (progn
      (defalias 'pycscope-event-window 'event-window)
      (defalias 'pycscope-event-point 'event-point)
      (defalias 'pycscope-recenter 'recenter)
      )
  (defun pycscope-event-window (event)
    "Return the window at which the mouse EVENT occurred."
    (posn-window (event-start event)))
  (defun pycscope-event-point (event)
    "Return the point at which the mouse EVENT occurred."
    (posn-point (event-start event)))
  (defun pycscope-recenter (&optional n window)
    "Center point in WINDOW and redisplay frame.  With N, put point on line N."
    (save-selected-window
      (if (windowp window)
	  (select-window window))
      (recenter n)))
  )


(defun pycscope-show-entry-internal (file line-number
					&optional save-mark-p window arrow-p)
  "Display the buffer corresponding to FILE and LINE-NUMBER
in some window.  If optional argument WINDOW is given,
display the buffer in that WINDOW instead.  The window is
not selected.  Save point on mark ring before goto
LINE-NUMBER if optional argument SAVE-MARK-P is non-nil.
Put `overlay-arrow-string' if arrow-p is non-nil.
Returns the window displaying BUFFER."
  (let (buffer old-pos old-point new-point forward-point backward-point
	       line-end line-length)
    (if (and (stringp file)
	     (integerp line-number))
	(progn
	  (unless (file-readable-p file)
	    (error "%s is not readable or exists" file))
	  (setq buffer (find-file-noselect file))
	  (if (windowp window)
	      (set-window-buffer window buffer)
	    (setq window (display-buffer buffer)))
	  (set-buffer buffer)
	  (if (> line-number 0)
	      (progn
		(setq old-pos (point))
		(goto-line line-number)
		(setq old-point (point))
		(if (and pycscope-adjust pycscope-adjust-range)
		    (progn
		      ;; Calculate the length of the line specified by cscope.
		      (end-of-line)
		      (setq line-end (point))
		      (goto-char old-point)
		      (setq line-length (- line-end old-point))

		      ;; Search forward and backward for the pattern.
		      (setq forward-point (search-forward
					   pycscope-symbol
					   (+ old-point
					      pycscope-adjust-range) t))
		      (goto-char old-point)
		      (setq backward-point (search-backward
					    pycscope-symbol
					    (- old-point
					       pycscope-adjust-range) t))
		      (if forward-point
			  (progn
			    (if backward-point
				(setq new-point
				      ;; Use whichever of forward-point or
				      ;; backward-point is closest to old-point.
				      ;; Give forward-point a line-length advantage
				      ;; so that if the symbol is on the current
				      ;; line the current line is chosen.
				      (if (<= (- (- forward-point line-length)
						 old-point)
					      (- old-point backward-point))
					  forward-point
					backward-point))
			      (setq new-point forward-point)))
			(if backward-point
			    (setq new-point backward-point)
			  (setq new-point old-point)))
		      (goto-char new-point)
		      (beginning-of-line)
		      (setq new-point (point)))
		  (setq new-point old-point))
		(set-window-point window new-point)
		(if (and pycscope-allow-arrow-overlays arrow-p)
		    (set-marker overlay-arrow-position (point))
		  (set-marker overlay-arrow-position nil))
		(or (not save-mark-p)
		    (= old-pos (point))
		    (push-mark old-pos))
		))

	  (if pycscope-marker
	      (progn ;; The search was successful.  Save the marker so it
                     ;; can be returned to by pycscope-pop-mark.
		(ring-insert pycscope-marker-ring pycscope-marker)
		;; Unset pycscope-marker so that moving between matches
		;; (pycscope-next-symbol, etc.) does not fill
		;; pycscope-marker-ring.
		(setq pycscope-marker nil)))
          (setq pycscope-marker-window window)
	  )
      (message "No entry found at point."))
    )
  window)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; functions in *pycscope* buffer which lists the search results
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pycscope-select-entry-other-window ()
  "Display the entry at point in other window, select the window.
Push current point on mark ring and select the entry window."
  (interactive)
  (let ((file (get-text-property (point) 'pycscope-file))
	(line-number (get-text-property (point) 'pycscope-line-number))
	window)
    (setq window (pycscope-show-entry-internal file line-number t))
    (if (windowp window)
	(select-window window))
    ))


(defun pycscope-select-entry-one-window ()
  "Display the entry at point in one window, select the window."
  (interactive)
  (let ((file (get-text-property (point) 'pycscope-file))
	(line-number (get-text-property (point) 'pycscope-line-number))
	window)
    (setq window (pycscope-show-entry-internal file line-number t))
    (if (windowp window)
	(progn
	  (select-window window)
	  (sit-for 0)	;; Redisplay hack to allow delete-other-windows
			;; to continue displaying the correct location.
	  (delete-other-windows window)
	  ))
    ))


(defun pycscope-select-entry-specified-window (window)
  "Display the entry at point in a specified window, select the window."
  (interactive)
  (let ((file (get-text-property (point) 'pycscope-file))
	(line-number (get-text-property (point) 'pycscope-line-number)))
    (setq window (pycscope-show-entry-internal file line-number t window))
    (if (windowp window)
	  (select-window window))
    ))


(defun pycscope-mouse-select-entry-other-window (event)
  "Display the entry over which the mouse event occurred, select the window."
  (interactive "e")
  (let ((ep (pycscope-event-point event))
	(win (pycscope-event-window event))
	buffer file line-number window)
    (if ep
        (progn
          (setq buffer (window-buffer win)
                file (get-text-property ep 'pycscope-file buffer)
                line-number (get-text-property ep 'pycscope-line-number buffer))
          (select-window win)
          (setq window (pycscope-show-entry-internal file line-number t))
          (if (windowp window)
              (select-window window))
          )
      (message "No entry found at point.")
      )
    ))


(defun pycscope-show-entry-other-window ()
  "Display the entry at point in other window.
Point is not saved on mark ring."
  (interactive)
  (let ((file (get-text-property (point) 'pycscope-file))
	(line-number (get-text-property (point) 'pycscope-line-number)))
    (pycscope-show-entry-internal file line-number nil nil t)
    ))


(defun pycscope-buffer-search (do-symbol do-next)
  "The body of the following four functions."
  (let* (line-number old-point point
		     (search-file (not do-symbol))
		     (search-prev (not do-next))
		     (direction (if do-next 1 -1))
		     (old-buffer (current-buffer))
		     (old-buffer-window (get-buffer-window old-buffer))
		     (buffer (get-buffer pycscope-output-buffer-name))
		     (buffer-window (get-buffer-window (or buffer (error "The *pycscope* buffer does not exist yet"))))
		     )
    (set-buffer buffer)
    (setq old-point (point))
    (forward-line direction)
    (setq point (point))
    (setq line-number (get-text-property point 'pycscope-line-number))
    (while (or (not line-number)
	       (or (and do-symbol (= line-number -1))
		   (and search-file  (/= line-number -1))))
      (forward-line direction)
      (setq point (point))
      (if (or (and do-next (>= point (point-max)))
	      (and search-prev (<= point (point-min))))
	  (progn
	    (goto-char old-point)
	    (error "The %s of the *pycscope* buffer has been reached"
		   (if do-next "end" "beginning"))))
      (setq line-number (get-text-property point 'pycscope-line-number)))
    (if (eq old-buffer buffer) ;; In the *pycscope* buffer.
	(pycscope-show-entry-other-window)
      (pycscope-select-entry-specified-window old-buffer-window) ;; else
      (if (windowp buffer-window)
	  (set-window-point buffer-window point)))
    (set-buffer old-buffer)
    ))


(defun pycscope-display-buffer ()
  "Display the *pycscope* buffer."
  (interactive)
  (let ((buffer (get-buffer pycscope-output-buffer-name)))
    (if buffer
        (pop-to-buffer buffer)
      (error "The *pycscope* buffer does not exist yet"))))


(defun pycscope-display-buffer-toggle ()
  "Toggle pycscope-display-pycscope-buffer, which corresponds to
\"Auto display *pycscope* buffer\"."
  (interactive)
  (setq pycscope-display-pycscope-buffer (not pycscope-display-pycscope-buffer))
  (message "The pycscope-display-pycscope-buffer variable is now %s."
           (if pycscope-display-pycscope-buffer "set" "unset")))


(defun pycscope-next-symbol ()
  "Move to the next symbol in the *pycscope* buffer."
  (interactive)
  (pycscope-buffer-search t t))


(defun pycscope-next-file ()
  "Move to the next file in the *pycscope* buffer."
  (interactive)
  (pycscope-buffer-search nil t))


(defun pycscope-prev-symbol ()
  "Move to the previous symbol in the *pycscope* buffer."
  (interactive)
  (pycscope-buffer-search t nil))


(defun pycscope-prev-file ()
  "Move to the previous file in the *pycscope* buffer."
  (interactive)
  (pycscope-buffer-search nil nil))


(defun pycscope-pop-mark ()
  "Pop back to where cscope was last invoked."
  (interactive)

  ;; This function is based on pop-tag-mark, which can be found in
  ;; lisp/progmodes/etags.el.

  (if (ring-empty-p pycscope-marker-ring)
      (error "There are no marked buffers in the pycscope-marker-ring yet"))
  (let* ( (marker (ring-remove pycscope-marker-ring 0))
	  (old-buffer (current-buffer))
	  (marker-buffer (marker-buffer marker))
	  marker-window
	  (marker-point (marker-position marker))
	  (pycscope-buffer (get-buffer pycscope-output-buffer-name)) )

    ;; After the following both pycscope-marker-ring and pycscope-marker will be
    ;; in the state they were immediately after the last search.  This way if
    ;; the user now makes a selection in the previously generated *pycscope*
    ;; buffer things will behave the same way as if that selection had been
    ;; made immediately after the last search.
    (setq pycscope-marker marker)

    (if marker-buffer
	(if (eq old-buffer pycscope-buffer)
	    (progn ;; In the *pycscope* buffer.
	      (set-buffer marker-buffer)
	      (setq marker-window (display-buffer marker-buffer))
	      (set-window-point marker-window marker-point)
	      (select-window marker-window))
	  (switch-to-buffer marker-buffer))
      (error "The marked buffer has been deleted"))
    (goto-char marker-point)
    (set-buffer old-buffer)))


(defun pycscope-set-initial-directory (cs-id)
  "Set the pycscope-initial-directory variable.  The
pycscope-initial-directory variable, when set, specifies the directory
where searches for the pycscope database directory should begin.  This
overrides the current directory, which would otherwise be used."
  (interactive "DPyCscope Initial Directory: ")
  (setq pycscope-initial-directory cs-id))


(defun pycscope-unset-initial-directory ()
  "Unset the pycscope-initial-directory variable."
  (interactive)
  (setq pycscope-initial-directory nil)
  (message "The pycscope-initial-directory variable is now unset."))


(defun pycscope-help ()
  (interactive)
  (message
   (format "RET=%s, SPC=%s, o=%s, n=%s, p=%s, q=%s, h=%s"
	   "Select"
	   "Show"
	   "SelectOneWin"
	   "ShowNext"
	   "ShowPrev"
	   "Quit"
	   "Help")))


(defun pycscope-bury-buffer ()
  "Clean up pycscope, if necessary, and bury the buffer."
  (interactive)
  (let ()
    (if overlay-arrow-position
	(set-marker overlay-arrow-position nil))
    (setq overlay-arrow-position nil
	  overlay-arrow-string nil)
    (bury-buffer (get-buffer pycscope-output-buffer-name))
    ))


(defun pycscope-quit ()
  (interactive)
  (pycscope-bury-buffer)
  (kill-buffer pycscope-output-buffer-name)
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pycscope-canonicalize-directory (dir)
  (or dir
      (setq dir default-directory))
  (setq dir (file-name-as-directory
	     (expand-file-name (substitute-in-file-name dir))))
  dir
  )


(defun pycscope-search-directory-hierarchy (directory)
  "Look for a pycscope database in the directory hierarchy.
Starting from DIRECTORY, look upwards for a pycscope database."
  (let (this-directory database-dir)
    (catch 'done
      (if (file-regular-p directory)
	  (throw 'done directory))
      (setq directory (pycscope-canonicalize-directory directory)
	    this-directory directory)
      (while this-directory
	(if (or (file-exists-p (concat this-directory pycscope-database-file))
		(file-exists-p (concat this-directory pycscope-index-file)))
	    (progn
	      (setq database-dir this-directory)
	      (throw 'done database-dir)
	      ))
	(if (string-match "^\\(/\\|[A-Za-z]:[\\/]\\)$" this-directory)
	    (throw 'done directory))
	(setq this-directory (file-name-as-directory
			      (file-name-directory
			       (directory-file-name this-directory))))
	))
    ))


(defun pycscope-find-info (top-directory)
  "Locate a suitable pycscope database directory.
First, `pycscope-database-regexps' is used to search for a suitable
database directory.  If a database location cannot be found using this
variable, then the current directory is searched, then the parent,
then the parent's parent, until a pycscope database directory is found,
or the root directory is reached.  If the root directory is reached,
the current directory will be used."
  (let (info regexps dir-regexp this-directory)
    (setq top-directory (pycscope-canonicalize-directory
			 (or top-directory pycscope-initial-directory)))
    (catch 'done
      ;; Try searching using `pycscope-database-regexps' ...
      (setq regexps pycscope-database-regexps)
      (while regexps
	(setq dir-regexp (car (car regexps)))
	(cond
	 ( (stringp dir-regexp)
	   (if (string-match dir-regexp top-directory)
	       (progn
		 (setq info (cdr (car regexps)))
		 (throw 'done t)
		 )) )
	 ( (and (symbolp dir-regexp) dir-regexp)
	   (progn
	     (setq info (cdr (car regexps)))
	     (throw 'done t)
	     ) ))
	(setq regexps (cdr regexps))
	)

      ;; Try looking in the directory hierarchy ...
      (if (setq this-directory
		(pycscope-search-directory-hierarchy top-directory))
	  (progn
	    (setq info (list (list this-directory)))
	    (throw 'done t)
	    ))

      ;; Should we add any more places to look?

      )		;; end catch
    (if (not info)
	(setq info (list (list top-directory))))
    info
    ))


(defun pycscope-make-entry-line (func-name line-number line)
  ;; The format of entry line:
  ;; func-name[line-number]______line
  ;; <- pycscope-name-line-width ->
  ;; `format' of Emacs doesn't have "*s" spec.
  (let* ((fmt (format "%%%ds %%s" pycscope-name-line-width))
	 (str (format fmt (format "%s[%s]" func-name line-number) line))
	 beg end)
    (if pycscope-use-face
	(progn
	  (setq end (length func-name))
	  (put-text-property 0 end 'face 'pycscope-function-face str)
	  (setq beg (1+ end)
		end (+ beg (length line-number)))
	  (put-text-property beg end 'face 'pycscope-line-number-face str)
	  (setq end (length str)
		beg (- end (length line)))
	  (put-text-property beg end 'face 'pycscope-line-face str)
	  ))
    str))


(defun pycscope-process-filter (process output)
  "Accept cscope process output and reformat it for human readability.
Magic text properties are added to allow the user to select lines
using the mouse."
  (let ( (old-buffer (current-buffer)) )
    (unwind-protect
	(progn
	  (set-buffer (process-buffer process))
	  ;; Make buffer-read-only nil
	  (let (buffer-read-only line file function-name line-number moving)
	    (setq moving (= (point) (process-mark process)))
	    (save-excursion
	      (goto-char (process-mark process))
	      ;; Get the output thus far ...
	      (if pycscope-process-output
		  (setq pycscope-process-output (concat pycscope-process-output
						      output))
		(setq pycscope-process-output output))
	      ;; Slice and dice it into lines.
	      ;; While there are whole lines left ...
	      (while (and pycscope-process-output
			  (string-match "\\([^\n]+\n\\)\\(\\(.\\|\n\\)*\\)"
					pycscope-process-output))
		(setq file				nil
		      glimpse-stripped-directory	nil
		      )
		;; Get a line
		(setq line (substring pycscope-process-output
				      (match-beginning 1) (match-end 1)))
		(setq pycscope-process-output (substring pycscope-process-output
						       (match-beginning 2)
						       (match-end 2)))
		(if (= (length pycscope-process-output) 0)
		    (setq pycscope-process-output nil))

		;; This should always match.
		(if (string-match
		     "^\\([^ \t]+\\)[ \t]+\\([^ \t]+\\)[ \t]+\\([0-9]+\\)[ \t]+\\(.*\\)\n"
		     line)
		    (progn
		      (let (str)
			(setq file (substring line (match-beginning 1)
					      (match-end 1))
			      function-name (substring line (match-beginning 2)
						       (match-end 2))
			      line-number (substring line (match-beginning 3)
						     (match-end 3))
			      line (substring line (match-beginning 4)
					      (match-end 4))
			      )
			;; If the current file is not the same as the previous
			;; one ...
			(if (not (and pycscope-last-file
				      (string= file pycscope-last-file)))
			    (progn
			      ;; The current file is different.

			      ;; Insert a separating blank line if
			      ;; necessary.
			      (if pycscope-last-file (insert "\n"))
			      ;; Insert the file name
			      (setq str (concat "*** " file ":"))
			      (if pycscope-use-face
				  (put-text-property 0 (length str)
						     'face 'pycscope-file-face
						     str))
			      (pycscope-insert-with-text-properties
			       str
			       (expand-file-name file)
			       ;; Yes, -1 is intentional
			       -1)
			      (insert "\n")
			      ))
			(if (not pycscope-first-match)
			    (setq pycscope-first-match-point (point)))
			;; ... and insert the line, with the
			;; appropriate indentation.
			(pycscope-insert-with-text-properties
			 (pycscope-make-entry-line function-name
						 line-number
						 line)
			 (expand-file-name file)
			 line-number)
			(insert "\n")
			(setq pycscope-last-file file)
			(if pycscope-first-match
			    (setq pycscope-matched-multiple t)
			  (setq pycscope-first-match
				(cons (expand-file-name file)
				      (string-to-number line-number))))
			))
		  (insert line "\n")
		  ))
	      (set-marker (process-mark process) (point))
	      )
	    (if moving
		(goto-char (process-mark process)))
	    (set-buffer-modified-p nil)
	    ))
      (set-buffer old-buffer))
    ))


(defun pycscope-process-sentinel (process event)
  "Sentinel for when the cscope process dies."
  (let* ( (buffer (process-buffer process)) window update-window
         (done t) (old-buffer (current-buffer))
	 (old-buffer-window (get-buffer-window old-buffer)) )
    (set-buffer buffer)
    (save-window-excursion
      (save-excursion
	(if (or (and (setq window (get-buffer-window buffer))
		     (= (window-point window) (point-max)))
		(= (point) (point-max)))
	    (progn
	      (setq update-window t)
	      ))
	(delete-process process)
	(let (buffer-read-only continue)
	  (goto-char (point-max))
	  (if (and pycscope-suppress-empty-matches
		   (= pycscope-output-start (point)))
	      (delete-region pycscope-item-start (point-max))
	    (progn
	      (if (not pycscope-start-directory)
		  (setq pycscope-start-directory default-directory))
	      (insert pycscope-separator-line)
	      ))
	  (setq continue
		(and pycscope-search-list
		     (not (and pycscope-first-match
			       pycscope-stop-at-first-match-dir
			       (not pycscope-stop-at-first-match-dir-meta)))))
	  (if continue
	      (setq continue (pycscope-search-one-database)))
	  (if continue
	      (progn
		(setq done nil)
		)
	    (progn
	      (insert "\nSearch complete.")
	      (if pycscope-display-times
		  (let ( (times (current-time)) pycscope-stop elapsed-time )
		    (setq pycscope-stop (+ (* (car times) 65536.0)
					 (car (cdr times))
					 (* (car (cdr (cdr times))) 1.0E-6)))
		    (setq elapsed-time (- pycscope-stop pycscope-start-time))
		    (insert (format "  Search time = %.2f seconds."
				    elapsed-time))
		    ))
	      (setq pycscope-process nil)
	      (if pycscope-running-in-xemacs
		  (setq modeline-process ": Search complete"))
	      (if pycscope-start-directory
		  (setq default-directory pycscope-start-directory))
	      (if (not pycscope-first-match)
		  (message "No matches were found."))
	      )
	    ))
	(set-buffer-modified-p nil)
	))
    (if (and done pycscope-first-match-point update-window)
	(if window
	    (set-window-point window pycscope-first-match-point)
	  (goto-char pycscope-first-match-point))
      )
    (cond
     ( (not done)		;; we're not done -- do nothing for now
       (if update-window
	   (if window
	       (set-window-point window (point-max))
	     (goto-char (point-max))))
       )
     ( pycscope-first-match
       (if pycscope-display-pycscope-buffer
           (if (and pycscope-edit-single-match (not pycscope-matched-multiple))
               (pycscope-show-entry-internal(car pycscope-first-match)
                                           (cdr pycscope-first-match) t))
         (pycscope-select-entry-specified-window old-buffer-window))
       )
     )
    (if (and done (eq old-buffer buffer) pycscope-first-match)
	(pycscope-help))
    (set-buffer old-buffer)
    ))


(defun pycscope-search-one-database ()
  "Pop a database entry from pycscope-search-list and do a search there."
  (let ( next-item options pycscope-directory database-file outbuf done
		   base-database-file-name)
    (setq outbuf (get-buffer-create pycscope-output-buffer-name))
    (save-excursion
      (catch 'finished
	(set-buffer outbuf)
	(setq options '("-L"))
	(while (and (not done) pycscope-search-list)
	  (setq next-item (car pycscope-search-list)
		pycscope-search-list (cdr pycscope-search-list)
		base-database-file-name pycscope-database-file
		)
	  (if (listp next-item)
	      (progn
		(setq pycscope-directory (car next-item))
		(if (not (stringp pycscope-directory))
		    (setq pycscope-directory
			  (pycscope-search-directory-hierarchy
			   default-directory)))
		(if (file-regular-p pycscope-directory)
		    (progn
		      ;; Handle the case where `pycscope-directory' is really
		      ;; a full path name to a pycscope database.
		      (setq base-database-file-name
			    (file-name-nondirectory pycscope-directory)
			    pycscope-directory
			    (file-name-directory pycscope-directory))
		      ))
		(setq pycscope-directory
		      (file-name-as-directory pycscope-directory))
		(if (not (member pycscope-directory pycscope-searched-dirs))
		    (progn
		      (setq pycscope-searched-dirs (cons pycscope-directory
						       pycscope-searched-dirs)
			    done t)
		      ))
		)
	    (progn
	      (if (and pycscope-first-match
		       pycscope-stop-at-first-match-dir
		       pycscope-stop-at-first-match-dir-meta)
		  (throw 'finished nil))
	      ))
	  )
	(if (not done)
	    (throw 'finished nil))
	(if (car (cdr next-item))
	    (let (newopts)
	      (setq newopts (car (cdr next-item)))
	      (if (not (listp newopts))
		  (error (format "Pycscope options must be a list: %s" newopts)))
	      (setq options (append options newopts))
	      ))
	(if pycscope-command-args
	    (setq options (append options pycscope-command-args)))
	(setq database-file (concat pycscope-directory base-database-file-name)
	      pycscope-searched-dirs (cons pycscope-directory
					 pycscope-searched-dirs)
	      )

	;; The database file and the directory containing the database file
	;; must both be writable.
	(if (or (not (file-writable-p database-file))
		(not (file-writable-p (file-name-directory database-file)))
		pycscope-do-not-update-database)
	    (setq options (cons "-d" options)))

	(goto-char (point-max))
	(setq pycscope-item-start (point))
	(if (string= base-database-file-name pycscope-database-file)
	    (insert "\nDatabase directory: " pycscope-directory "\n"
		    pycscope-separator-line)
	  (insert "\nDatabase directory/file: "
		  pycscope-directory base-database-file-name "\n"
		  pycscope-separator-line))
	;; Add the correct database file to search
	(setq options (cons base-database-file-name options))
	(setq options (cons "-f" options))
	(setq pycscope-output-start (point))
	(setq default-directory pycscope-directory)
	(if pycscope-filter-func
	    (progn
	      (setq pycscope-process-output nil
		    pycscope-last-file nil
		    )
	      (setq pycscope-process
		    (apply 'start-process "cscope" outbuf
			   pycscope-program options))
	      (set-process-filter pycscope-process pycscope-filter-func)
	      (set-process-sentinel pycscope-process pycscope-sentinel-func)
	      (set-marker (process-mark pycscope-process) (point))
	      (process-kill-without-query pycscope-process)
	      (if pycscope-running-in-xemacs
		  (setq modeline-process ": Searching ..."))
	      (setq buffer-read-only t)
	      )
	  (apply 'call-process pycscope-program nil outbuf t options)
	  )
	t
	))
    ))


(defun pycscope-call (msg args &optional directory filter-func sentinel-func)
  "Generic function to call to process cscope requests.
ARGS is a list of command-line arguments to pass to the cscope
process.  DIRECTORY is the current working directory to use (generally,
the directory in which the pycscope database is located, but not
necessarily), if different that the current one.  FILTER-FUNC and
SENTINEL-FUNC are optional process filter and sentinel, respectively."
  (let ( (outbuf (get-buffer-create pycscope-output-buffer-name))
         (old-buffer (current-buffer)) )
    (if pycscope-process
	(error "A cscope search is still in progress -- only one at a time is allowed"))
    (setq directory (pycscope-canonicalize-directory
                     (or pycscope-initial-directory directory)))
    (if (eq outbuf old-buffer) ;; In the *pycscope* buffer.
	(if pycscope-marker-window
	    (progn
	      ;; Assume that pycscope-marker-window is the window, from the
	      ;; users perspective, from which the search was launched and the
	      ;; window that should be returned to upon pycscope-pop-mark.
	      (set-buffer (window-buffer pycscope-marker-window))
	      (setq pycscope-marker (point-marker))
	      (set-buffer old-buffer)))
	(progn ;; Not in the *pycscope* buffer.
	  ;; Set the pycscope-marker-window to whichever window this search
	  ;; was launched from.
	  (setq pycscope-marker-window (get-buffer-window old-buffer))
	(setq pycscope-marker (point-marker))))
    (save-excursion
      (set-buffer outbuf)
      (if pycscope-display-times
	  (let ( (times (current-time)) )
	    (setq pycscope-start-time (+ (* (car times) 65536.0) (car (cdr times))
				       (* (car (cdr (cdr times))) 1.0E-6)))))
      (setq default-directory directory
	    pycscope-start-directory nil
	    pycscope-search-list (pycscope-find-info directory)
	    pycscope-searched-dirs nil
	    pycscope-command-args args
	    pycscope-filter-func filter-func
	    pycscope-sentinel-func sentinel-func
	    pycscope-first-match nil
	    pycscope-first-match-point nil
	    pycscope-stop-at-first-match-dir-meta (memq t pycscope-search-list)
	    pycscope-matched-multiple nil
	    buffer-read-only nil)
      (buffer-disable-undo)
      (erase-buffer)
      (setq truncate-lines pycscope-truncate-lines)
      (if msg
	  (insert msg "\n"))
      (pycscope-search-one-database)
      )
    (if pycscope-display-pycscope-buffer
	(progn
	  (pop-to-buffer outbuf)
	  (pycscope-help))
      (set-buffer outbuf))
    (goto-char (point-max))
    (pycscope-list-entry-mode)
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar pycscope-unix-index-process-buffer-name "*pycscope-indexing-buffer*"
  "The name of the buffer to use for displaying indexing status/progress.")


(defvar pycscope-unix-index-process-buffer nil
  "The buffer to use for displaying indexing status/progress.")


(defvar pycscope-unix-index-process nil
  "The current indexing process.")


(defun pycscope-unix-index-files-sentinel (process event)
  "Simple sentinel to print a message saying that indexing is finished."
  (let (buffer)
    (save-window-excursion
      (save-excursion
	(setq buffer (process-buffer process))
	(set-buffer buffer)
	(goto-char (point-max))
	(insert pycscope-separator-line "\nIndexing finished\n")
	(delete-process process)
	(setq pycscope-unix-index-process nil)
	(set-buffer-modified-p nil)
	))
    ))


(defun pycscope-unix-index-files-internal (top-directory header-text args)
  "Core function to call the indexing script."
  (let ()
    (save-excursion
      (setq top-directory (pycscope-canonicalize-directory top-directory))
      (setq pycscope-unix-index-process-buffer
	    (get-buffer-create pycscope-unix-index-process-buffer-name))
      (display-buffer pycscope-unix-index-process-buffer)
      (set-buffer pycscope-unix-index-process-buffer)
      (setq buffer-read-only nil)
      (setq default-directory top-directory)
      (buffer-disable-undo)
      (erase-buffer)
      (if header-text
	  (insert header-text))
      (setq args (append args
			 (list "-i" pycscope-index-file
			       "-f" pycscope-database-file
			       (if pycscope-use-relative-paths
				   "." top-directory))))
      (if pycscope-index-recursively
	  (setq args (cons "-r" args)))
      (setq pycscope-unix-index-process
	    (apply 'start-process "pycscope-indexer"
		   pycscope-unix-index-process-buffer
		   pycscope-indexing-script args))
      (set-process-sentinel pycscope-unix-index-process
			    'pycscope-unix-index-files-sentinel)
      (process-kill-without-query pycscope-unix-index-process)
      )
    ))


(defun pycscope-index-files-only (top-directory)
  "Index files in a directory.
This function looks for an existing list of files to index, and then
indexes the files from that list."
  (interactive "DIndex files in directory: ")
  (let ()
    (pycscope-unix-index-files-internal
     top-directory
     (format "Creating cscope index `%s' in:\n\t%s\n\n%s"
	     pycscope-database-file top-directory pycscope-separator-line)
     '("-d"))
    ))


(defun pycscope-index-files (top-directory)
  "Index files in a directory.
This function creates a list of files to index, and then indexes
the listed files.
The variable, \"pycscope-index-recursively\", controls whether or not
subdirectories are indexed."
  (interactive "DIndex files in directory: ")
  (let ()
    (pycscope-unix-index-files-internal
     top-directory
     (format "Creating cscope index `%s' in:\n\t%s\n\n%s"
	     pycscope-database-file top-directory pycscope-separator-line)
     nil)
    ))


(defun pycscope-create-list-of-files-to-index (top-directory)
  "Create a list of files to index.
The variable, \"pycscope-index-recursively\", controls whether or not
subdirectories are indexed."
  (interactive "DCreate file list in directory: ")
  (let ()
    (pycscope-unix-index-files-internal
     top-directory
     (format "Creating cscope file list `%s' in:\n\t%s\n\n"
	     pycscope-index-file top-directory)
     '("-l"))
    ))


(defun pycscope-edit-list-of-files-to-index ()
  "Search for and edit the list of files to index.
If this functions causes a new file to be edited, that means that a
pycscope.out file was found without a corresponding pycscope.files file."
  (interactive)
  (let (info directory file)
    (setq info (pycscope-find-info nil))
    (if (/= (length info) 1)
	(error "There is no unique pycscope database directory!"))
    (setq directory (car (car info)))
    (if (not (stringp directory))
	(setq directory
	      (pycscope-search-directory-hierarchy default-directory)))
    (setq file (concat (file-name-as-directory directory) pycscope-index-file))
    (find-file file)
    (message (concat "File: " file))
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pycscope-tell-user-about-directory ()
  "Display the name of the directory containing the pycscope database."
  (interactive)
  (let (info directory)
    (setq info (pycscope-find-info nil))
    (if (= (length info) 1)
	(progn
	  (setq directory (car (car info)))
	  (message (concat "PyCscope directory: " directory))
	  )
      (let ( (outbuf (get-buffer-create pycscope-info-buffer-name)) )
	(display-buffer outbuf)
	(save-excursion
	  (set-buffer outbuf)
	  (buffer-disable-undo)
	  (erase-buffer)
	  (insert "PyCscope search directories:\n")
	  (while info
	    (if (listp (car info))
		(progn
		  (setq directory (car (car info)))
		  (if (not (stringp directory))
		      (setq directory
			    (pycscope-search-directory-hierarchy
			     default-directory)))
		  (insert "\t" directory "\n")
		  ))
	    (setq info (cdr info))
	    )
	  )
	))
    ))


(defun pycscope-dired-directory ()
  "Run dired upon the pycscope database directory.
If possible, the cursor is moved to the name of the pycscope database
file."
  (interactive)
  (let (info directory buffer p1 p2 pos)
    (setq info (pycscope-find-info nil))
    (if (/= (length info) 1)
	(error "There is no unique pycscope database directory!"))
    (setq directory (car (car info)))
    (if (not (stringp directory))
	(setq directory
	      (pycscope-search-directory-hierarchy default-directory)))
    (setq buffer (dired-noselect directory nil))
    (switch-to-buffer buffer)
    (set-buffer buffer)
    (save-excursion
      (goto-char (point-min))
      (setq p1 (search-forward pycscope-index-file nil t))
      (if p1
	  (setq p1 (- p1 (length pycscope-index-file))))
      )
    (save-excursion
      (goto-char (point-min))
      (setq p2 (search-forward pycscope-database-file nil t))
      (if p2
	  (setq p2 (- p2 (length pycscope-database-file))))
      )
    (cond
     ( (and p1 p2)
       (if (< p1 p2)
	   (setq pos p1)
	 (setq pos p2))
       )
     ( p1
       (setq pos p1)
       )
     ( p2
       (setq pos p2)
       )
     )
    (if pos
	(set-window-point (get-buffer-window buffer) pos))
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pycscope-extract-symbol-at-cursor (extract-filename)
  (let* ( (symbol-chars (if extract-filename
			    pycscope-filename-chars
			  pycscope-symbol-chars))
	  (symbol-char-regexp (concat "[" symbol-chars "]"))
	  )
    (save-excursion
      (buffer-substring-no-properties
       (progn
	 (if (not (looking-at symbol-char-regexp))
	     (re-search-backward "\\w" nil t))
	 (skip-chars-backward symbol-chars)
	 (point))
       (progn
	 (skip-chars-forward symbol-chars)
	 (point)
	 )))
    ))


(defun pycscope-prompt-for-symbol (prompt extract-filename)
  "Prompt the user for a symbol."
  (let (sym)
    (setq sym (pycscope-extract-symbol-at-cursor extract-filename))
    (if (or (not sym)
	    (string= sym "")
	    (not (and pycscope-running-in-xemacs
		      pycscope-no-mouse-prompts current-mouse-event
		      (or (mouse-event-p current-mouse-event)
			  (misc-user-event-p current-mouse-event))))
	    ;; Always prompt for symbol in dired mode.
	    (eq major-mode 'dired-mode)
	    )
	(setq sym (read-from-minibuffer prompt sym))
      sym)
    ))


(defun pycscope-find-this-symbol (symbol)
  "Locate a symbol in source code."
  (interactive (list
		(pycscope-prompt-for-symbol "Find this symbol: " nil)
		))
  (let ( (pycscope-adjust t) )	 ;; Use fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding symbol: %s" symbol)
		 (list "-0" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


(defun pycscope-find-global-definition (symbol)
  "Find a symbol's global definition."
  (interactive (list
		(pycscope-prompt-for-symbol "Find this global definition: " nil)
		))
  (let ( (pycscope-adjust t) )	 ;; Use fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding global definition: %s" symbol)
		 (list "-1" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


(defun pycscope-find-global-definition-no-prompting ()
  "Find a symbol's global definition without prompting."
  (interactive)
  (let ( (symbol (pycscope-extract-symbol-at-cursor nil))
	 (pycscope-adjust t) )	 ;; Use fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding global definition: %s" symbol)
		 (list "-1" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


(defun pycscope-find-called-functions (symbol)
  "Display functions called by a function."
  (interactive (list
		(pycscope-prompt-for-symbol
		 "Find functions called by this function: " nil)
		))
  (let ( (pycscope-adjust nil) )	 ;; Disable fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding functions called by: %s" symbol)
		 (list "-2" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


(defun pycscope-find-functions-calling-this-function (symbol)
  "Display functions calling a function."
  (interactive (list
		(pycscope-prompt-for-symbol
		 "Find functions calling this function: " nil)
		))
  (let ( (pycscope-adjust t) )	 ;; Use fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding functions calling: %s" symbol)
		 (list "-3" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


(defun pycscope-find-this-text-string (symbol)
  "Locate where a text string occurs."
  (interactive (list
		(pycscope-prompt-for-symbol "Find this text string: " nil)
		))
  (let ( (pycscope-adjust t) )	 ;; Use fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding text string: %s" symbol)
		 (list "-4" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


(defun pycscope-find-egrep-pattern (symbol)
  "Run egrep over the pycscope database."
  (interactive (list
		(let (pycscope-no-mouse-prompts)
		  (pycscope-prompt-for-symbol "Find this egrep pattern: " nil))
		))
  (let ( (pycscope-adjust t) )	 ;; Use fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding egrep pattern: %s" symbol)
		 (list "-6" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


(defun pycscope-find-this-file (symbol)
  "Locate a file."
  (interactive (list
		(let (pycscope-no-mouse-prompts)
		  (pycscope-prompt-for-symbol "Find this file: " t))
		))
  (let ( (pycscope-adjust nil) )	 ;; Disable fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding file: %s" symbol)
		 (list "-7" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


(defun pycscope-find-files-including-file (symbol)
  "Locate all files #including a file."
  (interactive (list
		(let (pycscope-no-mouse-prompts)
		  (pycscope-prompt-for-symbol
		   "Find files #including this file: " t))
		))
  (let ( (pycscope-adjust t) )	;; Use fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding files #including file: %s" symbol)
		 (list "-8" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


(defun pycscope-find-assignments-to-symbol (symbol)
  "Locate all assignments to a given symbol."
  (interactive (list
		(let (pycscope-no-mouse-prompts)
		  (pycscope-prompt-for-symbol
		   "Find assignments to symbol: " t))
		))
  (let ( (pycscope-adjust t) )	;; Use fuzzy matching.
    (setq pycscope-symbol symbol)
    (pycscope-call (format "Finding assignments to symbol: %s" symbol)
		 (list "-9" symbol) nil 'pycscope-process-filter
		 'pycscope-process-sentinel)
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar pycscope-minor-mode nil
  "")
(make-variable-buffer-local 'pycscope-minor-mode)
(put 'pycscope-minor-mode 'permanent-local t)


(defun pycscope-minor-mode (&optional arg)
  ""
  (progn
    (setq pycscope-minor-mode (if (null arg) t (car arg)))
    (if pycscope-minor-mode
	(progn
	  (easy-menu-add pycscope:menu pycscope:map)
	  (run-hooks 'pycscope-minor-mode-hooks)
	  ))
    pycscope-minor-mode
    ))


(defun pycscope:hook ()
  ""
  (progn
    (pycscope-minor-mode)
    ))


(or (assq 'pycscope-minor-mode minor-mode-map-alist)
    (setq minor-mode-map-alist (cons (cons 'pycscope-minor-mode pycscope:map)
				     minor-mode-map-alist)))

(add-hook 'python-mode-hook (function pycscope:hook))
(add-hook 'dired-mode-hook (function pycscope:hook))

(provide 'xpycscope)
