module tests::TestImplodes

import util::FileSystem;
import lang::StateDuino::ast::Load;
import lang::StateDuino::ast::Main;
import IO;
import Set;
import ParseTree;
import Exception;

private void iterateOverAllSDOFiles(void (loc f) perFile) {
	sdoFiles = crawl(|project://stateduino/examples/|);
	for (/file(l) <- sdoFiles, l.extension == "sdo") {
		println("Checking <l>");
		perFile(l);
	}
}
private void iterateOverAllCSDOFiles(void (loc f) perFile) {
	sdoFiles = crawl(|project://stateduino/examples/|);
	for (/file(l) <- sdoFiles, l.extension == "csdo") {
		println("Checking <l>");
		perFile(l);
	}
}

public rel[loc,str, str] checkForImplodeErrors() {
	result = {};
	iterateOverAllSDOFiles(void (loc f) {
		try {
			getStateMachine(f);
		}
		catch IllegalArgument(el, msg) : result += {<f, "<el>", msg>};
	});
	iterateOverAllCSDOFiles(void (loc f) {
		try {
			getCoordinator(f);
		}
		catch IllegalArgument(el, msg) : result += {<f, "<el>", msg>};
	});
	return result;
}

public set[loc] searchForInstance(bool (StateMachine s) tryMatch) {
	result = {};
	iterateOverAllSDOFiles(void (loc f) {
		if (tryMatch(getStateMachine(f))) {
			result += {f};
		}
	});
	return result;
}
