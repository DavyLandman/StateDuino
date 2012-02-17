module lang::StateDuino::semantics::Checker

import Message;
import IO;
import lang::StateDuino::ast::Main;
import lang::StateDuino::semantics::Concepts;




public set[Message] fastCheck(StateMachine sm) {
	set[Message] result ={};
	visit(sm) {
		case p:param(str name, _) : 
			if (! (name in validParameterTypes)) {
				println("found problem");
				result += {error("Type <name> is not supported",p@location)};
			}
	};
	return result;
}