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
		case c:chain(/fork(_), _) : 
			result += getInvalidForkChainMessage(c);
		case c:chain(/forkDescription(_,_), _) : 
			result += getInvalidForkChainMessage(c);
	};
	return result;
}
//(left.offset, left.length + right.length + (right.offset - (left.offset + left.length)));
private set[Message] getInvalidForkChainMessage(chain(StateTransition forkFrom, StateTransition to)) {
	str m = "A fork cannot be followed by another action or fork.";
	loc left = forkFrom@location;
	loc right = to@location;	
	return { error(m, left), error(m, right)};
}
