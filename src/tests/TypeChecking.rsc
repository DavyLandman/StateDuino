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

public test bool testInvalidTypes() {
	set[Message] messages = runFastCheckOn("StateMachine Test(xxx invalid)");
	if (size(messages) == 0) {
		return false;	
	}
	if (error("Type xxx is not supported", _) <- messages) {
		return true;
	}
	return false;
}