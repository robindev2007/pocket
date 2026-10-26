import { Router } from 'express';
import { authMiddleware } from '../common/middleware';
import { PeopleController } from './people.controller';

const peopleRouter: Router = Router();
const controller = new PeopleController();

// Guard all people routes with JWT authentication
peopleRouter.use(authMiddleware);

peopleRouter.get('/', controller.getPeople);
peopleRouter.get('/:name/ledger', controller.getPersonLedger);

export { peopleRouter };
