import os
import common

const (
	name = 'ls'
)

struct Options {
	one_file_per_line bool
}

fn ls_cmd(dirs []string, opts &Options) {
	if dirs.len == 0 {
		list_dir_contents(os.getwd(), opts)
		return
	}

	output_header := dirs.len > 1
	for d in dirs {
		if output_header {
			println('$d:')
		}
		list_dir_contents(d, opts)
	}
}

fn list_dir_contents(dir string, opts &Options) {
	mut d_contents := os.ls(dir) or {
		eprintln('$dir is not a directory')
		return
	}

	locale_aware_alphabetical_sort(mut d_contents)
	if opts.one_file_per_line {
		for dc in d_contents.filter(check_for_hidden_symbol(it)) {
			print('${resolve_label(dc)}\n')
		}
	}
}

fn resolve_label(d string) string {
	if os.is_dir(d) {
		return '$d/'
	}
	return '$d'
}

fn check_for_hidden_symbol(name string) bool {
	if name.len >= 1 {
		return !name.starts_with('.')
	}
	return true
}

fn locale_aware_alphabetical_sort(mut l []string) {
	l.sort_with_compare(fn (a &string, b &string) int {
		a_lower := a.to_lower()
		b_lower := b.to_lower()

		if a_lower < b_lower {
			return -1
		}

		if a_lower > b_lower {
			return 1
		}

		return 0
	})
}

// Print messages and exit
[noreturn]
fn success_exit(messages ...string) {
	for message in messages {
		println(message)
	}
	exit(0)
}

fn run_ls(args []string) {
	mut fp := common.flag_parser(args)
	fp.application(name)
	fp.usage_example('[OPTION]... [FILE]...')
	fp.description('List information about the FILEs (the current directory by default).')
	fp.description('Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.')

	fp.description('Mandatory arguments to long options are mandatory for short options too.')
	mut opts := Options{
		one_file_per_line: fp.bool('', `1`, false, "list one file per line. Avoid '\\n' with -q or -b")
	}

	help := fp.bool('help', 0, false, 'display this help and exit')
	version := fp.bool('version', 0, false, 'output version information and exit')
	if help {
		success_exit(fp.usage())
	}
	if version {
		success_exit('$name $common.coreutils_version()')
	}

	file_args := fp.finalize() or { common.exit_with_error_message(name, err.msg()) }
	ls_cmd(file_args, &opts)
}

fn main() {
	run_ls(os.args)
}
