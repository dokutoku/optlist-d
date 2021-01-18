/*
 *                       Command Line Option Parser
 *
 *   File    : optlist.c
 *   Purpose : Provide getopt style command line option parsing
 *   Author  : Michael Dipperstein
 *   Date    : August 1, 2007
 *
 ****************************************************************************
 *
 * OptList: A command line option parsing library
 * Copyright (C) 2007, 2014 2018 by
 * Michael Dipperstein (mdipperstein@gmail.com)
 *
 * This file is part of the OptList library.
 *
 * OptList is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or (at
 * your option) any later version.
 *
 * OptList is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
 * General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
module optlist_d.optlist;


private static import core.memory;
private static import core.stdc.stdio;
private static import core.stdc.string;

/* CONSTANTS */

/**
 * this option has no arguement
 */
public enum OL_NOINDEX = -1;

/* TYPE DEFINITIONS */

/**
 * The structure for storing one of the command line options.
 */
public struct option_t
{
	/**
	 * the current character option character
	 */
	char option;

	/**
	 * pointer to arguments for this option
	 */
	char* argument;

	/**
	 * index into argv[] containing the argument
	 */
	int argIndex;

	/**
	 * the next option in the linked list
	 */
	.option_t* next;
}

/* FUNCTIONS */

/**
 * This function is similar to the POSIX function getopt. All options and their corresponding arguments are returned in a linked list. This function should only be called once per an option list and it does not modify argv or argc.
 *
 * Params:
 *      argc = the number of command line arguments (including the name of the executable)
 *      argv = pointer to the open binary file to write encoded output
 *      options = getopt style option list. A null terminated string of single character options. Follow an option with a colon to indicate that it requires an argument.
 *
 * Effects: Creates a link list of command line options and their arguments.
 *
 * NOTE: The caller is responsible for freeing up the option list when it is no longer needed.
 *
 * Returns: option_t type value where the option and arguement fields contain the next option symbol and its argument (if any). The argument field will be set to null if there are no arguments or if you specify an option with missing arguments or if memory allocation fails. The option field will be set to PO_NO_OPT if no more options are found.
 */
extern (C)
pure nothrow @trusted @nogc
public .option_t* GetOptList(const int argc, scope const char** argv, const char* options)

	in
	{
		if (argc > 1) {
			assert(argv != null);
			assert(options != null);
		}
	}

	do
	{
		/* start with first argument and nothing found */
		int nextArg = 1;
		.option_t* head = null;
		.option_t* tail = null;

		/* loop through all of the command line arguments */
		while (nextArg < argc) {
			size_t argIndex = 1;

			while ((core.stdc.string.strlen(argv[nextArg]) > argIndex) && (argv[nextArg][0] == '-')) {
				/* attempt to find a matching option */
				size_t optIndex = .MatchOpt(argv[nextArg][argIndex], options);

				if (options[optIndex] == argv[nextArg][argIndex]) {
					/* we found the matching option */
					if (head == null) {
						head = .MakeOpt(options[optIndex], null, .OL_NOINDEX);

						if (head == null) {
							return null;
						}

						tail = head;
					} else {
						tail.next = .MakeOpt(options[optIndex], null, .OL_NOINDEX);

						if (tail.next == null) {
							.FreeOptList(head);

							return null;
						}

						tail = tail.next;
					}

					if (options[optIndex + 1] == ':') {
						/* the option found should have a text arguement */
						argIndex++;

						if (core.stdc.string.strlen(argv[nextArg]) > argIndex) {
							/* no space between argument and option */
							tail.argument = cast(char*)(&(argv[nextArg][argIndex]));
							tail.argIndex = nextArg;
						} else if (nextArg < argc) {
							/* there must be space between the argument option */
							nextArg++;
							tail.argument = cast(char*)(argv[nextArg]);
							tail.argIndex = nextArg;
						}

						/* done with argv[nextArg] */
						break;
					}
				}

				argIndex++;
			}

			nextArg++;
		}

		return head;
	}

/**
 * This function uses pureMalloc to allocate space for an option_t type structure and initailizes the structure with the values passed as a parameter.
 *
 * Params:
 *      option = this option character
 *      argument = pointer string containg the argument for option. Use null for no argument
 *      index = argv[index] contains argument use OL_NOINDEX for no argument
 *
 * Effects: A new option_t type variable is created on the heap.
 *
 * Returns: Pointer to newly created and initialized option_t type structure. null if space for structure can't be allocated.
 */
pure nothrow @trusted @nogc
private .option_t* MakeOpt(const char option, char* argument, const int index)

	do
	{
		.option_t* opt = cast(.option_t*)(core.memory.pureMalloc(.option_t.sizeof));

		if (opt != null) {
			opt.option = option;
			opt.argument = argument;
			opt.argIndex = index;
			opt.next = null;
		} else {
			return null;
		}

		return opt;
	}

/**
 * This function will free all the elements in an option_t type linked list starting from the node passed as a parameter.
 *
 * Params:
 *      list = head of linked list to be freed
 *
 * Effects: All elements of the linked list pointed to by list will be freed and list will be set to null.
 */
extern (C)
pure nothrow @trusted @nogc
public void FreeOptList(.option_t* list)

	do
	{
		.option_t* head = list;
		list = null;

		while (head != null) {
			.option_t* next = head.next;
			core.memory.pureFree(head);
			head = next;
		}
	}

/**
 * This function searches for an arguement in an option list. It will return the index to the option matching the arguement or the index to the null if none is found.
 *
 * Params:
 *      arguement = character arguement to be matched to an option in the option list
 *      options = getopt style option list. A null terminated string of single character options. Follow an option with a colon to indicate that it requires an argument.
 *
 * Returns: Index of argument in option list. Index of end of string if arguement does not appear in the option list.
 */
pure nothrow @trusted @nogc @live
private size_t MatchOpt(const char argument, const char* options)

	in
	{
		assert(options != null);
	}

	do
	{
		size_t optIndex = 0;

		/* attempt to find a matching option */
		while ((options[optIndex] != '\0') && (options[optIndex] != argument)) {
			do {
				optIndex++;
			} while ((options[optIndex] != '\0') && (options[optIndex] == ':'));
		}

		return optIndex;
	}

/**
 * This is function accepts a pointer to the name of a file along with path information and returns a pointer to the first character that is not part of the path.
 *
 * Params:
 *      fullPath = pointer to an array of characters containing a file name and possible path modifiers.
 *
 * Returns: Returns a pointer to the first character after any path information.
 */
extern (C)
pure nothrow @trusted @nogc @live
public char* FindFileName(scope const char* fullPath)

	do
	{
		/* path deliminators */
		static immutable char[3] delim = ['\\', '/', ':'];

		/* start of file name */
		const (char)* start = fullPath;

		/* find the first character after all file path delimiters */
		for (size_t i = 0; i < 3; i++) {
			const (char)* tmp = core.stdc.string.strrchr(start, delim[i]);

			if (tmp != null) {
				start = tmp + 1;
			}
		}

		return cast(char*)(start);
	}
