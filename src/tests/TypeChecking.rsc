module tests::TypeChecking

import lang::StateDuino::ast::Main;
import lang::StateDuino::ast::Load;
import lang::StateDuino::semantics::Checker;
import Message;
import Set;
import IO;

private set[Message] runFastCheckOn(str input) {
	return fastCheck(getStateMachine(input));
}
private bool checkContainsErrorMessage(str input, str message) {
	set[Message] messages = runFastCheckOn(input);
	if (error(message, _) <- messages) {
		return true;
	}
	return false;
}

public test bool testInvalidTypes() {
	return checkContainsErrorMessage("StateMachine Test(xxx invalid)",
		"Type xxx is not supported"
		);
}

public test bool testValidStateTransitionChain() {
	set[Message] messages = runFastCheckOn("StateMachine Test T1=\>T2=\>T3?");
	return size(messages) == 0;
}

private bool checkInvalidTransitionChain(str inp, str forkName) {
	return checkContainsErrorMessage(inp,
		"A fork (<forkName>) cannot be followed by another action or fork."
		);
}
public test bool testInvalidStateTransitionChain() {
	return checkInvalidTransitionChain("StateMachine Test T1=\>T2=\>T3?=\>T4", "T3?");
}
public test bool testInvalidStateTransitionChain2() {
	return checkInvalidTransitionChain("StateMachine Test T1=\>T2=\>T3? { yes =\> T5 } =\>T4", "T3?");
}
public test bool testInvalidStateTransitionChain3() {
	return checkInvalidTransitionChain("StateMachine Test T3? { yes =\> T5 } =\>T4", "T3?");
}
public test bool testInvalidStateTransitionChain4() {
	return checkInvalidTransitionChain("StateMachine Test T3?=\>T4", "T3?");
}
public test bool testInvalidStateTransitionChain5() {
	return checkInvalidTransitionChain("StateMachine Test T3?=\>T4=\>T5", "T3?");
}

public test bool testInvalidForkConditions() {
	return checkContainsErrorMessage("StateMachine Test T? { yes =\> T1 yes =\> T1 }",
		"Fork condition yes is already defined"
		);
}
public test bool testInvalidForkConditionsName() {
	return checkContainsErrorMessage("StateMachine Test T? { ys =\> T1 no =\> T1 }",
		"Fork condition ys is not valid"
		);
}
