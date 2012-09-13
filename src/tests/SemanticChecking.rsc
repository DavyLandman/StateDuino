module tests::SemanticChecking

import lang::StateDuino::ast::Main;
import lang::StateDuino::ast::Load;
import lang::StateDuino::semantics::Checker;
import Message;
import Set;
import IO;
import util::FileSystem;

private set[Message] runFastCheckOn(str input) {
	return performFastCheck(getStateMachine(input));
}
private set[Message] runBigCheckOn(str input) {
	return performFullCheck(getStateMachine(input));
}
private bool checkContainsErrorMessage(str input, str message) {
	set[Message] messages = runFastCheckOn(input);
	if (error(message, _) <- messages) {
		return true;
	}
	//iprintln(input);
	//iprintln(messages);
	return false;
}
private bool verifyContainsErrorMessage(str input, str message) {
	set[Message] messages = runBigCheckOn(input);
	if (error(message, _) <- messages) {
		return true;
	}
	//iprintln(input);
	//iprintln(messages);
	return false;
}
private bool verifyNotContainsErrorMessage(str input, str message) {
	set[Message] messages = runBigCheckOn(input);
	if (error(message, _) <- messages) {
		//iprintln(input);
		//iprintln(messages);
		return false;
	}
	return true;
}

private bool verifyContainsNoErrorMessages(str input) {
	set[Message] result = runBigCheckOn(input);
	if (size(result) == 0) {
		return true;
	}
	//iprintln(input);
	//iprintln(result);
	return false;
}


public test bool testInvalidTypes() {
	return checkContainsErrorMessage("StateMachine Test(xxx invalid) start = T1",
		"Type xxx is not supported"
		);
}


public test bool testValidStateTransitionChain() {
	return verifyContainsNoErrorMessages("StateMachine Test start = T1 fork T1 { c1? =\> A2; T1; }");
}

private bool checkInvalidTransitionChain(str inp, str forkName) {
	return checkContainsErrorMessage(inp,
		"There should be no more actions after a call to a fork (<forkName>)."
		);
}
private bool verifyInvalidTransitionChain(str inp, str forkName) {
	return verifyContainsErrorMessage(inp,
		"There should be no more actions after a call to a fork (<forkName>)."
		);
}
public test bool testInvalidActionChain() {
	return checkInvalidTransitionChain("StateMachine Test start = T1 fork T1 { c1? =\> fork T3 { c1? =\> T1; } A2; T1; }", "T3");
}
public test bool testInvalidActionChain2() {
	return checkInvalidTransitionChain("StateMachine Test start = T1 fork T1 { c1? =\> fork { c1? =\> T1; } T1; }", "nameless");
}
public test bool testInvalidActionChain3() {
	return checkContainsErrorMessage("StateMachine Test start = T1 fork T1 { c1? =\> chain X { T1; } T1; }", "You cannot nest a chain (X).");
}
public test bool testInvalidActionChain4() {
	return checkContainsErrorMessage("StateMachine Test start = T1 fork T1 { c1? =\> chain X { T1; } }", "You cannot nest a chain (X).");
}
public test bool testInvalidActionChain5() {
	return checkContainsErrorMessage("StateMachine Test start = T1 fork T1 { c1? =\> X; } chain X { chain Y { T1; } }", "You cannot nest a chain (Y).");
}
public test bool testEmptyBody() {
	return checkContainsErrorMessage("StateMachine Test start = T1 fork T1 { }", "You must define at least one condition for T1.");
}
public test bool testEmptyBody2() {
	return checkContainsErrorMessage("StateMachine Test start = T1 fork T1 { A1; }", "You must define at least one condition for T1.");
}
public test bool testEmptyBody3() {
	return checkContainsErrorMessage("StateMachine Test start = T1 fork T1 { c1? =\> }", "You must define at least one action for condition.");
}
public test bool testEmptyBody4() {
	return checkContainsErrorMessage("StateMachine Test start = X chain X { }", "You must define at least one action for X.");
}
public test bool testInvalidChainWithForkReference() {
	return verifyInvalidTransitionChain("StateMachine Test start = T1 fork T1 { c1? =\> T3; T4; } fork T3 { default =\> T1; }", "T3");
}

private bool verifyDoesntEndInFork(str inp, str wrongEnd) {
	return verifyContainsErrorMessage(inp,
		"<wrongEnd> does not end in a fork."
		) || verifyContainsErrorMessage(inp,
		"<wrongEnd> has a definition loop."
		) ;
}

public test bool alwaysExecutingActionCannotEndInAFork() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 fork T1 { A1; T1; c1? =\> A2; T1; }",
		"Always executing actions of T1 cannot end in a fork (T1)");
}

public test bool testEveryThingEndsWithAFork() {
	return verifyDoesntEndInFork("StateMachine Test start = T1 fork T1 { c1? =\> A1; A2; }", "A2");
}
public test bool testEveryThingEndsWithAFork2() {
	return verifyDoesntEndInFork("StateMachine Test start = T1 fork T1 { c1? =\> A1; } chain A1 { A2; } chain A2 { A3; }", "A3");
}
public test bool testEveryThingEndsWithAFork3() {
	return verifyDoesntEndInFork("StateMachine Test start = T1 fork T1 { c1? =\> A1; } chain A1 { A2; } chain A2 { A1; }", "A1");
}
public test bool testEveryThingEndsWithAFork4() {
	return verifyDoesntEndInFork("StateMachine Test start = T1 fork T1 { c1? =\> immediate fork T2 { c2? =\> T2; } }", "T2");
}
public test bool testEveryThingEndsWithAFork5() {
	return verifyDoesntEndInFork("StateMachine Test start = T1 fork T1 { c1? =\> immediate fork T2 { c2? =\> C2; } } chain C2 { A1; }", "A1");
}

// these tests need some formal boolean checking stuff!
public test bool unreachableBooleanCondition() {
	return verifyContainsErrorMessage("StateMachine Test start = F1 fork F1 { c1? =\> F1; c1? and c2? =\> A1; F1; } ",
		"This condition will never match since previous conditions would have already matched"
		);
}
public test bool unreachableBooleanCondition2() {
	return verifyContainsErrorMessage("StateMachine Test start = F1 fork F1 { c1? and not c1? =\> A1; F1; } ",
		"This condition can never be true"
		);
}
public test bool unreachableBooleanCondition3() {
	return verifyContainsErrorMessage("StateMachine Test start = F1 fork F1 { c1? or not c1? =\> F1; c2? =\> A1; F1; } ",
		"This condition will never match since previous conditions would always match"
		);
}

public test bool testUndefinedStart() {
	return verifyContainsErrorMessage("StateMachine Test start = T1",
		"T1 is undefined"
		);
}

public test bool testAlreadyDefine() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 fork T1 { c1? =\> T1; } fork T1 { c2? =\> T1; }",
		"T1 is already defined"
		);
}
public test bool testAlreadyDefine2() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 fork T1 { c1? =\> C1; } chain C1 { T1; } chain C1 { T1; }",
		"C1 is already defined"
		);
}

public test bool testSingleDefineWork() {
	return verifyContainsNoErrorMessages("StateMachine Test start = T1 fork T1 {c1? =\> T2;} fork T2 { c2? =\> T3; } chain T3 { T1; }");
}
public test bool testNestedDefineWorks() {
	return verifyContainsNoErrorMessages("StateMachine Test start = T1 fork T1 { c1? =\> fork T1 { c2? =\> T1; } }");
}



private void iterateOverAllSDOFiles(void (loc f) perFile) {
	csfFiles = crawl(|project://stateduino/examples/|);
	for (/file(l) <- csfFiles, l.extension == "sdo") {
		perFile(l);
	}
}

public test bool verifyFullCheckWorks() {
	set[Message] messages = {};
	iterateOverAllSDOFiles(void (loc f) {
		messages += performFullCheck(getStateMachine(f));
	});
	if (size(messages) == 0) {
		return true;	
	}
	println(messages);
	return false;	
}