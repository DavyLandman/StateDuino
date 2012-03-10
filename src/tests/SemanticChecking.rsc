module tests::SemanticChecking

import lang::StateDuino::ast::Main;
import lang::StateDuino::ast::Load;
import lang::StateDuino::semantics::Checker;
import Message;
import Set;
import IO;

private set[Message] runFastCheckOn(str input) {
	return fastCheck(getStateMachine(input));
}
private set[Message] runBigCheckOn(str input) {
	return fullCheck(getStateMachine(input));
}
private bool checkContainsErrorMessage(str input, str message) {
	set[Message] messages = runFastCheckOn(input);
	if (error(message, _) <- messages) {
		return true;
	}
	return false;
}
private bool verifyContainsErrorMessage(str input, str message) {
	set[Message] messages = runBigCheckOn(input);
	if (error(message, _) <- messages) {
		return true;
	}
	return false;
}
private bool verifyNotContainsErrorMessage(str input, str message) {
	set[Message] messages = runBigCheckOn(input);
	if (error(message, _) <- messages) {
		return false;
	}
	return true;
}

private bool verifyContainsNoErrorMessages(str input) {
	set[Message] result = runBigCheckOn(input);
	if (size(result) == 0) {
		return true;
	}
	else {
		iprintln(result);
		return false;
	}
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
		"A fork (<forkName>) cannot be followed by another action or fork."
		);
}
private bool verifyInvalidTransitionChain(str inp, str forkName) {
	return verifyContainsErrorMessage(inp,
		"A fork (<forkName>) cannot be followed by another action or fork."
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
public test bool testInvalidStateTransitionChain2() {
	return verifyInvalidTransitionChain("StateMachine Test start = T1 fork T1 { c1? =\> T3; T4; } fork T3 { default =\> T1; }", "T3");
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

public test bool testInvalidForkConditionsName() {
	return checkContainsErrorMessage("StateMachine Test start = T? T? { ys =\> T1 no =\> T1 }",
		"Fork condition ys is not valid"
		);
}

public test bool testSingleActionNotAllowed() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 T1 ",
		"Single action T1 has no path to follow"
		);
}
public test bool testSingleActionNotAllowed2() {
	return verifyContainsErrorMessage("StateMachine Test start = T1? T1? ",
		"Single fork T1? has no path to follow"
		);
}
public test bool testSingleActionNotAllowed2() {
	return verifyNotContainsErrorMessage("StateMachine Test start = T1? T1? { yes =\> T2 } T2 =\> T1? ",
		"Single action T2 has no path to follow"
		);
}

public test bool testUndefinedStart() {
	return verifyContainsErrorMessage("StateMachine Test start = T1",
		"T1 is undefined"
		);
}

public test bool testUndefinedEnd() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 T1 =\> T4 =\> T2",
		"T2 is undefined"
		);
}

public test bool testUndefinedEnd2() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 T1 =\> T2?",
		"T2? is undefined"
		);
}
public test bool testUndefinedEnd3() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 T1 =\> T2 T2 =\> T3",
		"T3 is undefined"
		);
}

public test bool testAlreadyDefine() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 T1 =\> T2 T1 =\> T2",
		"T1 is already defined"
		);
}
public test bool testAlreadyDefine2() {
	return verifyContainsErrorMessage("StateMachine Test start = T1? T1? { yes =\> T1? } T1? { yes =\> T1? }",
		"T1? is already defined"
		);
}

public test bool testSingleDefineWork() {
	return verifyContainsNoErrorMessages("StateMachine Test start = T1 T1 =\> T2? T2? { yes =\> T3} T3 =\> T1");
}
public test bool testSingleDefineWork2() {
	return verifyContainsNoErrorMessages("StateMachine Test start = T1 T1 =\> T2? T2? { yes =\> T1 } ");
}

public test bool testNotTerminating() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 T1 =\> T2 =\> T1",
		"T1 will never terminate, you should end in a Fork"
		);
}
public test bool testNotTerminating2() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 T1 =\> !T2? !T2? { yes=\> T1 }",
		"T1 will never terminate, you should end in a Fork"
		);
}
public test bool testNotTerminating3() {
	return verifyContainsErrorMessage("StateMachine Test start = T1 T1 =\> T2? 
		!T2? { 
			yes=\> !T3? {
				yes =\> T1		
			} 
		}",
		"T1 will never terminate, you should end in a Fork"
		);
}

public test bool testWillTerminate() {
	return verifyNotContainsErrorMessage("StateMachine Test start = T1 T1 =\> !T2? !T2? { yes=\> T1 no =\> T4?} T4? { yes =\> T1 }",
		"T1 will never terminate, you should end in a Fork"
		);
}
public test bool testWillTerminate2() {
	return verifyNotContainsErrorMessage("StateMachine Test start = T1 T1 =\> !T2?
	!T2? { 
		yes=\> T1 
		no =\> !T4? { 
			yes =\> T1
			no =\> T5?
		}
	}
	T5? { yes =\> T1 } ",
		"T1 will never terminate, you should end in a Fork"
		);
}

public test bool testWillTerminate3() {
	return verifyNotContainsErrorMessage("StateMachine Test start = T1 T1 =\> T2? { 
		yes=\> T1 
	}
	",
		"T1 will never terminate, you should end in a Fork"
		);
}