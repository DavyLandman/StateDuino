module lang::StateDuino::semantics::Checker

import List;
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
		case chain([_*,f:fork(_), a:_, _*]) :  
				result += getInvalidForkChainMessage(f, a);
		case chain([_*, f:forkDescription(_,_), a:_, _*]) : 
			result += getInvalidForkChainMessage(f, a);
			
		case forkDescription(_, conditions) : {
				set[str] defined = {};
				for (a:action(condition,_) <- conditions) {
					if (condition in defined) {
						result += {error("Fork condition <condition> is already defined", a@location)};		
					}
					defined += { condition };
				}	
			}
	};
	return result;
}
//(left.offset, left.length + right.length + (right.offset - (left.offset + left.length)));
private set[Message] getInvalidForkChainMessage(StateTransition forkFrom, StateTransition to) {
	str m = "A fork cannot be followed by another action or fork.";
	loc left = forkFrom@location;
	loc right = to@location;	
	return { error(m, left), error(m, right)};
}
