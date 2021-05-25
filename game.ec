import "ecere"

#define DIM 15
#define MAX_SLOTS DIM*DIM*4
#define MAX_POINTS DIM*DIM

struct Step {
   int x;
   int y;
} Step;

struct Result {
   Step step;
   int result;
   int nSteps;
} Result;

struct P {
   int x;
	int y;
	S *slots[20];
   int nSlots;
	int r[3];
	int s;
} P;

struct S {
   P *scp;
	int d;
	P *points[5];
	int r;
	int s;
} Slot;

struct Net {
   Step steps[MAX_POINTS];
   int nSteps;
   S all_slots[MAX_SLOTS];
   int nAllSlots;
	S *active_slots[3][MAX_SLOTS];
   int nActiveSlots[3];
	P all_points[MAX_POINTS];
	P *empty_points[MAX_POINTS];
   int nEmptyPoints;
} Net;

bool isValidScp(P *p, int d) {
   int x, y;
   x = p->x - 7;
	y = p->y - 7;
	// 0 - vert, 1 - horiz, 2 - up, 3 - down
	if (d == 0 && y > -6 && y < 6) {
		return true;
	}
	if (d == 1 && x > -6 && x < 6) {
		return true;
	}
	if (d == 2 && (x > -6 && y < 6) && (x < 6 && y > -6)) {
		return true;
	}
	if (d == 3 && (x > -6 && y > -6) && (x < 6 && y < 6)) {
		return true;
	}
	return false;
}

P* getPoint(Net* net, int x, int y) {
   return net->all_points+(x*DIM+y);
}

void SlotInit(Net* net, S *s) {
   int i;
   P *p;
   s->points[2] = s->scp;
	if (s->d == 0) {
		s->points[0] = getPoint(net, s->scp->x, s->scp->y-2);
		s->points[1] = getPoint(net, s->scp->x, s->scp->y-1);
		s->points[3] = getPoint(net, s->scp->x, s->scp->y+1);
		s->points[4] = getPoint(net, s->scp->x, s->scp->y+2);
	} else if (s->d == 1) {
		s->points[0] = getPoint(net, s->scp->x-2, s->scp->y);
		s->points[1] = getPoint(net, s->scp->x-1, s->scp->y);
		s->points[3] = getPoint(net, s->scp->x+1, s->scp->y);
		s->points[4] = getPoint(net, s->scp->x+2, s->scp->y);
	} else if (s->d == 2) {
		s->points[0] = getPoint(net, s->scp->x-2, s->scp->y-2);
		s->points[1] = getPoint(net, s->scp->x-1, s->scp->y-1);
		s->points[3] = getPoint(net, s->scp->x+1, s->scp->y+1);
		s->points[4] = getPoint(net, s->scp->x+2, s->scp->y+2);
	} else if (s->d == 3) {
		s->points[0] = getPoint(net, s->scp->x-2, s->scp->y+2);
		s->points[1] = getPoint(net, s->scp->x-1, s->scp->y+1);
		s->points[3] = getPoint(net, s->scp->x+1, s->scp->y-1);
		s->points[4] = getPoint(net, s->scp->x+2, s->scp->y-2);
	}
	for(i = 0; i < 5; i++) {
      p = s->points[i];
      p->slots[p->nSlots] = s;
      p->nSlots++;
	}
}

void addStep(Net *net, int n, Step st) {
   int i,j,k;
   S *s;
   int c = n%2 + 1;
   P *p = getPoint(net, st.x, st.y);
   //printf("start::add_step(nstep=%d, (x=%d, y=%d))\n", n, st.x, st.y);
   if(p->s) PrintLn("Point is not empty");
   p->s = c;
   for(i = 0; i < net->nEmptyPoints; i++) {
      if(p == net->empty_points[i]) {
         for(j = i+1; j < net->nEmptyPoints; j++)
            net->empty_points[j-1] = net->empty_points[j];
         net->nEmptyPoints--;
         break;
      }
   }
   //printf("work::add_step(nEmptyPoints=%d)\n", net->nEmptyPoints);
   for(k = 0; k < p->nSlots; k++) {
      s = p->slots[k];
      if (s->s == 0) {
			p->r[0]--;
			p->r[c]++;
			s->s = c;
			s->r = 1;
			// delete active slot
         for(i = 0; i < net->nActiveSlots[0]; i++) {
            if(s == net->active_slots[0][i]) {
               for(j = i+1; j < net->nActiveSlots[0]; j++)
                  net->active_slots[0][j-1] = net->active_slots[0][j];
               net->nActiveSlots[0]--;
               break;
            }
         }
			net->active_slots[c][net->nActiveSlots[c]] = s;
         net->nActiveSlots[c]++;
		} else if (s->s == c) {
			p->r[c]++;
			s->r++;
		} else if (s->s != 3) {
			p->r[c]--;
			// delete active slot
         for(i = 0; i < net->nActiveSlots[s->s]; i++) {
            if(s == net->active_slots[s->s][i]) {
               for(j = i+1; j < net->nActiveSlots[s->s]; j++)
                  net->active_slots[s->s][j-1] = net->active_slots[s->s][j];
               net->nActiveSlots[s->s]--;
               break;
            }
         }
			s->s = 3;
		}
   }
   //printf("end::add_step()\n");
}

void NetInit(Net* net) {
   int i;
   int d;
   P *p;
   S *s;
   //printf("start::net_init(nsteps=%d)\n", net->nSteps);
   net->nEmptyPoints = 0;
   net->nAllSlots = 0;
   net->nActiveSlots[0] = 0;
   net->nActiveSlots[1] = 0;
   net->nActiveSlots[2] = 0;
   for (i = 0; i < MAX_POINTS; i++) {
      p = net->all_points + i;
      p->x = i/DIM;
      p->y = i%DIM;
      p->nSlots = 0;
      p->s = 0;
      p->r[0] = 0;
      p->r[1] = 0;
      p->r[2] = 0;
      net->empty_points[net->nEmptyPoints] = p;
      net->nEmptyPoints++;
      for(d = 0; d < 4; d++) {
			if (isValidScp(p, d)) {
				s = net->all_slots + net->nAllSlots;
            s->d = d;
            s->scp = p;
            s->r = 0;
            s->s = 0;
            net->active_slots[0][net->nActiveSlots[0]] = s;
            net->nActiveSlots[0]++;
            net->nAllSlots++;
			}
		}
   }
   //printf("work::net_init(nEmptyPoints=%d, nAllSlots=%d)\n", net->nEmptyPoints, net->nAllSlots);
   for(i = 0; i < net->nAllSlots; i++) {
      s = net->all_slots + i;
      SlotInit(net, s);
   }
   //printf("work::net_init() slot_init = ok\n");
   for(i = 0; i < net->nSteps; i++) {
      addStep(net, i, net->steps[i]);
   }
   //printf("end::net_init(nsteps=%d)\n", net->nSteps);
}

bool checkWin(Net net) {
   int i;
   S *s;
   for(i = 0; i < net.nActiveSlots[1]; i++) {
      s = net.active_slots[1][i];
		if(s->r == 5) {
			return true;
		}
	}
   for(i = 0; i < net.nActiveSlots[2]; i++) {
      s = net.active_slots[2][i];
		if(s->r == 5) {
			return true;
		}
	}
	return false;
}

bool checkDraw(Net net) {
   if(net.nActiveSlots[0] == 0 && net.nActiveSlots[1] == 0 && net.nActiveSlots[2] == 0) {
		//net.mes = " draw :("
		return true;
	} else {
		return false;
	}
}

int findSlot4(Net net, int c, Step *ret) {
   int i, j;
   int n = 0;
   S *s;
   P *p;
	//msg := fmt.Sprintf("%v :: find_slot_4(%v,%v)", c)
	for(i = 0;i < net.nActiveSlots[c];i++)  {
      s = net.active_slots[c][i];
		if (s->r == 4) {
			for(j = 0;j < 5;j++) {
            p = s->points[j];
				if (p->s == 0) {
					ret[n] = Step{p->x, p->y};
               n++;
					//msg := fmt.Sprintf("%v :: find_slot_4 ->(%v,%v)", c)
				}
			}
		}
	}
	//if len(ret) > 0 {
	//	log.Printf("%v :: find_slot4 -> %v", c, ret)
	//}
	return n;
}

int findPointX(Net net, int c, int r, int b, Step *ret) {
   int k, j;
   int n = 0;
   int i;
   S *s;
   P *p;
   //msg := fmt.Sprintf("%v :: find_point_x(%v,%v)", c, r, b)
	for (k = 0;k < net.nEmptyPoints;k++) {
      p = net.empty_points[k];
		i = 0;
		for (j = 0; j < p->nSlots;j++) {
         s = p->slots[j];
			if (s->s == c && s->r > r) {
				i++;
				if(i > b) {
					ret[n] = Step{p->x, p->y};
               n++;
					//msg = fmt.Sprintf("%v :: find_point_x(%v,%v) -> (%v, %v)", c, r, b, elm[0], elm[1])
				}
			}
		}
	}
	//if len(ret) > 0 {
	//	log.Printf("%v :: find_point_x(%v,%v) -> %v", c, r, b, ret)
	//}
	return n;
}

int calcPointMaxRate(Net net, int c, Step *ret) {
   int n = 0;
   int r = -1;
	int d = 0;
	int i = 0;
   int j, k = 0;
   P *p;
   S *s;
	printf("start::point_max_rate(c=%d)\n", c);
   for(k = 0; k < net.nEmptyPoints; k++) {
	   p = net.empty_points[k];
		d = 0;
      for(j = 0; j < p->nSlots; j++) {
		    s = p->slots[j];
			 if (s->s == 0) {
				d++;
			 } else if (s->s == c) {
				d += (1 + s->r) * (1 + s->r);
			 } else if (s->s != 3) {
				d += (1 + s->r) * (1 + s->r);
			 }
		}
		if (d > r) {
			i = 1;
			r = d;
			n = 0;
			ret[n] = Step{p->x, p->y};
         n++;
			//msg = fmt.Sprintf("%v :: point_max_rate(%v,%v) -> (%v, %v)", c, i, r, elm[0], elm[1])
		} else if(d == r) {
			i++;
         ret[n] = Step{p->x, p->y};
         n++;
			//msg = fmt.Sprintf("%v :: point_max_rate(%v,%v) -> (%v, %v)", c, i, r, elm[0], elm[1])
		}
	}
	//log.Printf("%v :: point_max_rate(%v,%v) -> %v", c, i, r, ret)
   printf("end::point_max_rate(c=%d) n=%d\n", c, n);
	return n;
}

Step calcPoint(Net net) {
   int c, n;
   int rn;
   Step ret[225];
   //
   printf("start::calc_point(nsteps=%d)\n", net.nSteps);
   c = net.nSteps%2+1;
   //
	n = findSlot4(net, c, ret);
	if(n == 0) {
		n = findSlot4(net, 3 - c, ret);
	}

	if(n == 0) {
		n = findPointX(net, c, 2, 1, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 2, 1, ret);
	}

	if (n == 0) {
		n = findPointX(net, c, 1, 5, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 1, 5, ret);
	}

	if (n == 0) {
		n = findPointX(net, c, 1, 4, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 1, 4, ret);
	}

	if (n == 0) {
		n = findPointX(net, c, 1, 3, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 1, 3, ret);
	}

	if (n == 0) {
		n = findPointX(net, c, 1, 2, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 1, 2, ret);
	}

	if (n == 0) {
		n = findPointX(net, c, 1, 1, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 1, 1, ret);
	}

	if (n == 0) {
		n = findPointX(net, c, 0, 10, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 0, 10, ret);
	}

	if (n == 0) {
		n = findPointX(net, c, 0, 9, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 0, 9, ret);
	}

	if (n == 0) {
		n = findPointX(net, c, 0, 8, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 0, 8, ret);
	}

	if (n == 0) {
		n = findPointX(net, c, 0, 7, ret);
	}
	if (n == 0) {
		n = findPointX(net, 3-c, 0, 7, ret);
	}

	if (n == 0) {
		n = calcPointMaxRate(net, c, ret);
	}
	//log.Println(ret)
	//n := rand.Intn(len(ret))
	//log.Println(n)
   rn = GetRandom(0, n-1);
   printf("end::calc_point(nsteps=%d, n=%d, rn=%d)\n", net.nSteps, n, rn);
	return ret[rn];
}

Result calcStep(Step* steps, int nSteps) {
   int i;
   int result = 0; // play
   Net net;
   Step newStep;
   printf("start::calc_step(nsteps=%d)\n", nSteps);
   net.nSteps = nSteps;
   for(i = 0; i < nSteps; i++) net.steps[i] = steps[i];
   NetInit(&net);
   //
	if(checkWin(net)) {
		result = 1; // "win"
	} else if (checkDraw(net)) {
		result = 2; //"draw"
	} else {
		newStep = calcPoint(net);
      addStep(&net, nSteps, newStep);
      net.nSteps++;
      if(checkWin(net)) {
			result = 1; // "win"
		} else if(checkDraw(net)) {
			result = 2; // "draw"
		} else {
			result = 0; // "play"
		}
	}
   printf("end::calc_step()\n");
	return Result {newStep, result, net.nSteps};
}