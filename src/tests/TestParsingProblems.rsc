module tests::TestParsingProblems

import util::FileSystem;
import lang::StateDuino::cst::Parse;
import IO;
import Set;
import ParseTree;
import Exception;

public test bool checkAll() {
	return (size(checkAllAmbiguities()) == 0)
		&& (size(checkParsingErrors()) == 0);
}

public rel[loc,Tree] checkAllAmbiguities() {
	result = {};
	iterateOverAllSDOFiles(void (loc f) {
		try {
			parsed = parseStateMachine(f);
			if (/a:amb(_) := parsed) {
				result += {<f, a>};
			}
		}
		catch: ;
	});
	iterateOverAllCSDOFiles(void (loc f) {
		try {
			parsed = parseCoordinator(f);
			if (/a:amb(_) := parsed) {
				result += {<f, a>};
			}
		}
		catch: ;
	});
	return result;
}

private void iterateOverAllSDOFiles(void (loc f) perFile) {
	csfFiles = crawl(|project://stateduino/examples/|);
	for (/file(l) <- csfFiles, l.extension == "sdo") {
		println("Checking <l>");
		perFile(l);
	}
}

private void iterateOverAllCSDOFiles(void (loc f) perFile) {
	csfFiles = crawl(|project://stateduino/examples/|);
	for (/file(l) <- csfFiles, l.extension == "csdo") {
		println("Checking <l>");
		perFile(l);
	}
}

public rel[loc,loc] checkParsingErrors() {
	result = {};
	iterateOverAllSDOFiles(void (loc f) {
		try {
			parsed = parseStateMachine(f);
		}
		catch ParseError(el) : result += {<f, el>};
	});
	iterateOverAllCSDOFiles(void (loc f) {
		try {
			parsed = parseCoordinator(f);
		}
		catch ParseError(el) : result += {<f, el>};
	});
	return result;
}

public set[loc] searchForInstance(bool (Tree tree) tryMatch) {
	result = {};
	iterateOverAllSDOFiles(void (loc f) {
		if (tryMatch(parseStateMachine(f))) {
			result += {f};
		}
	});
	return result;
}