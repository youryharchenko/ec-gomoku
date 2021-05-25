import "ecere"
import "game"

const int d = 40;
const int dim = 15;
const char* colorNames[2] = {"Black", "White"};
const char *headText =  "Human Step - MouseLeftButton, Computer Step - PageDown, Auto Play - End, New Game - Home, Exit - Esc";

class Gomoku : Window {
   //
public:
   int nSteps;
   Step steps[225];
   Color colors[2];
   Bitmap bitmaps[2];
	int cv[15];
   int ch[15];
   Point offset;
   bool changed;
   bool play;
	bool calc;
	bool autoPlay;
   char statText[1024];
   //
   caption = "Ecere Gomoku";
   background = lightGray;
   minClientSize = { 1068 /*800*/, 700 };
   //
   //borderStyle = sizable;
   //hasMaximize = true;
   //hasMinimize = true;
   hasClose = true;
   clientSize = { 1024, 768 };
   //
   font = { "Arial", 12, bold = true };
   FontResource yourTurnFont { "Arial", 12, bold = true, italic = true, window = this };
   icon = { ":Gomoku.png" };
   BitmapResource resBlack { ":Black.png", window = this };
   BitmapResource resWhite { ":White.png", window = this };
   BitmapResource resEmpty { ":Empty.png", window = this };
   //
   Gomoku() {
      int i;
      RandomSeed((uint)(GetTime() * 1000));
      nSteps = 1;
      steps[0] = Step{7,7};
      //
      colors[0] = black;
      colors[1] = white;
      bitmaps[0] = resBlack.bitmap;
      bitmaps[1] = resWhite.bitmap;
      changed = true;
      cv[0] = 0;
      ch[0] = 0;
      for (i = 1; i < dim; i++) {
         cv[i] = cv[i-1] + d;
         ch[i] = ch[i-1] + d;
      }
      strcpy(statText, "New Game");
      play = true;
   }

   Step getStepFromCoord(int cx, int cy) {
      int i, x, y;
      x = -1;
      y = -1;
      cx = cx - offset.x;
      cy = cy - offset.y;
      for (i = 0; i < dim; i++) {
         if(cx >= ch[i] && cx < ch[i]+d) {
            x = i;
            break;
         }
      }
      for (i = 0; i < dim; i++) {
         if(cy >= cv[i] && cy < cv[i]+d) {
            y = i;
            break;
         }
      }
      return Step {x, y};
   }

   bool OnKeyDown(Key key, unichar ch) {
      if(key == escape) Destroy(0);
      if(key == home) {
         strcpy(statText, "New Game");
		   steps[0] = Step{7, 7};
         nSteps = 1;
		   // changed = true
		   play = true;
		   calc = true;
		   autoPlay = false;
         Update(null);
      }
      if(key == pageDown) {
         if(play) {
            strcpy(statText, "Play");
            calc = true;
            Update(null);
         }
      }
      if(key == end) {
         if(play) {
            strcpy(statText, "Auto Play");
            calc = true;
            autoPlay = true;
            Update(null);
         }
      }
      return true;
   }

   bool OnLeftButtonDown(int x, int y, Modifiers mods) {
      Step st, s;
      int i;
      //PrintLn(x, " ", y);
      st = getStepFromCoord(x, y);
      //PrintLn(st.x, " ", st.y);
      if(st.x == -1 || st.y == -1) return true;
      for (i = 0; i < nSteps; i++) {
         s = steps[i];
			if (st.x == s.x && st.y == s.y) {
				return true;
			}
		}
      if (play) {
         steps[nSteps] = st;
         nSteps++;
         strcpy(statText, "Play");
         calc = true;
         Update(null);
      }
      return true;
   }

   void OnRedraw(Surface surface) {
      int i, j;
      int x, y;
      int hShift, vShift;
      //
      hShift = surface.width/2-(dim/2)*d;
      vShift = surface.height/2-(dim/2)*d;
      //
      surface.foreground = black;
      surface.TextOpacity(false);
      surface.WriteTextDots(center, 0, vShift/2, surface.width, headText, strlen(headText));
      surface.WriteTextDots(center, 0, vShift+d*dim+d/2, surface.width, statText, strlen(statText));
      //
      surface.offset = Point{hShift, vShift};
      offset = surface.offset;
      //
      for (i = 0; i < dim; i++) {
         for (j = 0; j < dim; j++) {
            surface.Blit(resEmpty.bitmap, ch[i], cv[j], 0, 0, d, d);
         }
      }

		for (i = 0; i < nSteps; i++) {
         // PrintLn(steps[i].x, " ", steps[i].y);
         x = ch[steps[i].x];
			y = cv[steps[i].y];
         // PrintLn(x, " ", y);
         if(i%2) surface.Blit(resWhite.bitmap, x, y, 0, 0, d, d);
         else surface.Blit(resBlack.bitmap, x, y, 0, 0, d, d);
         surface.foreground = colors[1-i%2];
         surface.TextOpacity(false);
         surface.WriteTextDotsf(center, x, y+d/4, d, "%d", i+1);
      }
   }
}

Gomoku gomoku {};

class GomokuApp : GuiApplication {
   bool Init() {
      //int i;
      //PrintLn(this.argc);
      //for (i = 0; i < this.argc; i++) {
      //   PrintLn(i, " ",  this.argv[i]);
      //}
      gomoku.Create();
      //panel.Create();
      return true;
   }

   bool Cycle(bool idle)
   {
      Result result;
      if (gomoku.play && gomoku.calc) {
			result = calcStep(gomoku.steps, gomoku.nSteps);
         printf("calcStep: r=%d, na=%d, nb=%d, (x=%d, y=%d)\n", result.result, result.nSteps, gomoku.nSteps, result.step.x, result.step.y);
         if(result.nSteps > gomoku.nSteps) {
            gomoku.steps[gomoku.nSteps] = result.step;
            gomoku.nSteps++;
         }
			if (result.result != 0) {
			   gomoku.play = false;
			   if (result.result == 1) {
					sprintf(gomoku.statText, "%s won!", colorNames[1-result.nSteps%2]);
				} else if (result.result == 2) {
					strcpy(gomoku.statText,"Draw!");
			   }
			}
			if (!gomoku.autoPlay) {
			   gomoku.calc = false;
			}
			gomoku.Update(null);
		}
      return true;
   }
   void Terminate()
   {
      //if(hosting)
      //   cornerBlocksService.Stop();
   }
}
