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
				result += {error("Type <name> is not supported",p@location)};
			}
		case chain(chain(_,f:fork(_)), _) : 
			result += getInvalidForkChainMessage(f);
		case chain(chain(_,f:forkDescription(_,_)), _) : 
			result += getInvalidForkChainMessage(f);
	};
	return result;
}

private set[Message] getInvalidForkChainMessage(StateTransition st) {
	return { error("A fork cannot be followed by another action or fork.", st@location)};
}
