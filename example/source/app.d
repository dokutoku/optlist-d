/*
 *                           OptList Usage Sample
 *
 *   File    : sample.c
 *   Purpose : Demonstrates usage of optlist library.
 *   Author  : Michael Dipperstein
 *   Date    : July 23, 2004
 *
 ****************************************************************************
 *
 * Sample: A optlist library sample usage program
 * Copyright (C) 2007, 2014 by
 * Michael Dipperstein (mdipperstein@gmail.com)
 *
 * This file is part of the optlist library.
 *
 * The optlist library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 *
 * The optlist library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
 * General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
module optlist_example.app;


private static import core.memory;
private static import core.stdc.stdio;
private static import core.stdc.stdlib;
private static import optlist_d;

nothrow @nogc
void print_help(char** argv)

	do
	{
		core.stdc.stdio.printf("Usage: %s <options>\n\n", optlist_d.FindFileName(argv[0]));
		core.stdc.stdio.printf("options:\n");
		core.stdc.stdio.printf("  -a : option excepting argument.\n");
		core.stdc.stdio.printf("  -b : option without arguments.\n");
		core.stdc.stdio.printf("  -c : option without arguments.\n");
		core.stdc.stdio.printf("  -d : option excepting argument.\n");
		core.stdc.stdio.printf("  -e : option without arguments.\n");
		core.stdc.stdio.printf("  -f : option without arguments.\n");
		core.stdc.stdio.printf("  -? : print out command line options.\n\n");
	}

/**
 * This is the main function for this program, it calls optlist to parse the command line input displays the results of the parsing.
 *
 * Params:
 *      argc = number of parameters
 *      argv = parameter list
 *
 * Effects: parses command line parameters
 *
 * Returns: EXIT_SUCCESS for success, otherwise EXIT_FAILURE.
 */
extern (C)
nothrow @nogc @live
int main(int argc, char** argv)

	do
	{
		/* get list of command line options and their arguments */
		optlist_d.option_t* optList = optlist_d.GetOptList(argc, argv, "a:bcd:ef?");

		if (optList == null) {
			version (Windows) {
				/*
				 * Crash when using stderr on Windows.
				 * https://issues.dlang.org/show_bug.cgi?id=19933
				 */
				core.stdc.stdio.printf("parse error.\n");
			} else {
				core.stdc.stdio.fprintf(core.stdc.stdio.stderr, "parse error.\n");
			}

			return core.stdc.stdlib.EXIT_FAILURE;
		}

		/* display results of parsing */
		while (optList != null) {
			optlist_d.option_t* thisOpt = optList;
			optList = optList.next;

			if (thisOpt.option == '?') {
				.print_help(argv);

				/* free the rest of the list */
				optlist_d.FreeOptList(thisOpt);

				return core.stdc.stdlib.EXIT_SUCCESS;
			}

			core.stdc.stdio.printf("found option %c\n", thisOpt.option);

			if (thisOpt.argument != null) {
				core.stdc.stdio.printf("\tfound argument %s", thisOpt.argument);
				core.stdc.stdio.printf(" at index %d\n", thisOpt.argIndex);
			} else {
				core.stdc.stdio.printf("\tno argument for this option\n");
			}

			/* done with this item, free it */
			core.memory.pureFree(thisOpt);
		}

		return core.stdc.stdlib.EXIT_SUCCESS;
	}
