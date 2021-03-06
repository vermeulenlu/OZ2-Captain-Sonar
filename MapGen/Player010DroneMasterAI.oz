functor
import
   Input

   OS %rand
   Browser
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream

   InitState
   UpdateState

   InitPosition
   Move
   Dive
   ChargeItem
   FireItem
   FireMine
   IsSurface
   SayMove
   SaySurface
   SayCharge
   SayMinePlaced
   SayMissileExplode
   SayMineExplode
   SayPassingDrone
   SayAnswerDrone
   SayPassingSonar
   SayAnswerSonar
   SayDeath
   SayDamageTaken
in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{InitState ID Color}
      fun{InitEnemies State N} NewState StateEn StateX StateY in
	 if N == 0 then
	    State
	 else
	    %Personnaliser le State de départ de chaque ennemi ici
	    StateEn = {UpdateState State.enemies [N#enemy(pos:null)]}
            StateX = {UpdateState State.xsure [N#null]}
            StateY = {UpdateState State.ysure [N#null]}
	    NewState = {UpdateState State [enemies#StateEn xsure#StateX ysure#StateY]}
	    {InitEnemies NewState N-1}
	 end
      end
      MidState
      NewState
   in
      %Personnaliser le State de départ ici
      MidState = state(
		    id:id(id:ID color:Color name:'DroneMaster')
		    hp:Input.maxDamage
		    nextCharge:sonar
		    missileCharge:0
		    sonarCharge:0
		    droneCharge:0
		    enemies:data(1:null)
		    surf:true
		    surfCharge:0
		    visited:nil
		    focus:null
		    xsure:xsure(1:null)
		    ysure:ysure(1:null)
		    sonarLaunchOnce:false
                    dead:false
		    )
      NewState = {InitEnemies MidState Input.nbPlayer}
      NewState
   end

   %Update un State avec une liste de tuple contenant les valeurs qui ont changé
   % state(a:1 b:2) + [b#3] = state(a:1 b:3)
   fun{UpdateState State L}
      {AdjoinList State L}
   end

%%%%%%%%%%%%%%%%%

   %Fonctions lancées à la réception des messages
   %Elles représentent le comportement du Sub

   %Choisit une position de départ
   fun{InitPosition State ID Position}
      fun{NewPos}
	 fun{MapRandomPos}
	    pt(x:({OS.rand} mod Input.nRow + 1) y:({OS.rand} mod Input.nColumn + 1))
	 end
	 fun{MapIsWater Pos}
	    if {List.nth {List.nth Input.map Pos.x} Pos.y} == 0 then
	       true
	    else
	       false
	    end
	 end
	 Pos
      in
	 Pos = {MapRandomPos}
	 if {MapIsWater Pos} then
	    Pos
	 else
	    {NewPos}
	 end
      end
      NewState
      RetPos
   in
      RetPos = {NewPos}
      NewState = {UpdateState State [visited#[RetPos] pos#RetPos]}
      ID = NewState.id
      Position = NewState.pos
      NewState
   end

%%%

   fun{Move State ID Position Direction}
      fun{CanMove State Pos}
	 fun{Visited State Pos}
	    fun{Check L Pos}
	       case L
	       of nil then false
	       []pt(x:X y:Y)|T then
		  if Pos.x == X andthen Pos.y == Y then
		     true
		  else
		     {Check T Pos}
		  end
	       end
	    end
	 in
	    {Check State.visited Pos}
	 end
      in
	 if Pos.x>0 andthen Pos.x=<Input.nRow andthen Pos.y>0 andthen Pos.y=<Input.nColumn andthen  {List.nth {List.nth Input.map Pos.x} Pos.y} == 0 andthen {Visited State Pos} == false then
	    true
	 else
	    false
	 end
      end
      fun{RandomMove State}
	 fun{SubRandom Try Pos}
	    if Try == 0 then
	       null
	    else Rand in
	       Rand = {OS.rand} mod 4
	       case Rand
	       of 0 then
		  if {CanMove State pt(x:Pos.x+1 y:Pos.y)} then
		     move(south pt(x:Pos.x+1 y:Pos.y))
		  else
		     {SubRandom Try-1 Pos}
		  end
	       [] 1 then
		  if {CanMove State pt(x:Pos.x-1 y:Pos.y)} then
		     move(north pt(x:Pos.x-1 y:Pos.y))
		  else
		     {SubRandom Try-1 Pos}
		  end
	       [] 2 then
		  if {CanMove State pt(x:Pos.x y:Pos.y-1)} then
		     move(west pt(x:Pos.x y:Pos.y-1))
		  else
		     {SubRandom Try-1 Pos}
		  end
	       [] 3 then
		  if {CanMove State pt(x:Pos.x y:Pos.y+1)} then
		     move(east pt(x:Pos.x y:Pos.y+1))
		  else
		     {SubRandom Try-1 Pos}
		  end
	       end
	    end
	 end
      in
	 Msg = {SubRandom 10 State.pos}
      end
      N
      Xn
      Yn
      DistX
      DistY
      Msg
      NewState
      Ret
   in

      if (State.focus \= null) then
	 N = State.focus
	 Xn = State.enemies.N.pos.x
	 Yn = State.enemies.N.pos.y
	 DistX = {Number.abs State.pos.x - Xn}
	 DistY = {Number.abs State.pos.y - Yn}
         /*
         if (DistX==0) then
	    if ((State.pos.x - Xn) < 0) then
	       if ({CanMove State pt(x:State.pos.x+1 y:State.pos.y)}) then
		  Msg = move(south pt(x:State.pos.x+1 y:State.pos.y))
	       else
		  if ({InBounds State.pos.x+1 State.pos.y} andthen {List.nth {List.nth Input.map State.pos.x+1} State.pos.y} == 0) then
		     Msg = null
		  else
		     if ({CanMove State pt(x:State.pos.x y:State.pos.y-1)}) then
			Msg = move(west pt(x:State.pos.x y:State.pos.y-1))
		     elseif ({CanMove State pt(x:State.pos.x y:State.pos.y+1)}) then
			Msg = move(east pt(x:State.pos.x y:State.pos.y+1))
		     elseif({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
			Msg = move(north pt(x:State.pos.x-1 y:State.pos.y))
		     end
		  end
	       end
	    else
	       if ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
		  Msg = move(north pt(x:State.pos.x-1 y:State.pos.y))
	       else
		  if ({InBounds State.pos.x-1 State.pos.y} andthen {List.nth {List.nth Input.map State.pos.x-1} State.pos.y} == 0) then
		     Msg = null
		  else
		     if ({CanMove State pt(x:State.pos.x y:State.pos.y-1)}) then
			Msg = move(west pt(x:State.pos.x y:State.pos.y-1))
		     elseif ({CanMove State pt(x:State.pos.x y:State.pos.y+1)}) then
			Msg = move(east pt(x:State.pos.x y:State.pos.y+1))
		     elseif({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
			Msg = move(south pt(x:State.pos.x+1 y:State.pos.y))
		     end
		  end
	       end
	    end
	 elseif (DistY==0) then
	    if ((State.pos.x - Xn) < 0) then
	       if ({CanMove State pt(x:State.pos.x y:State.pos.y+1)}) then
		  Msg = move(east pt(x:State.pos.x y:State.pos.y+1))
	       else
		  if ({InBounds State.pos.x State.pos.y+1} andthen {List.nth {List.nth Input.map State.pos.x} State.pos.y+1} == 0) then
		     Msg = null
		  else
		     if ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
			Msg = move(north pt(x:State.pos.x-1 y:State.pos.y))
		     elseif ({CanMove State pt(x:State.pos.x+1 y:State.pos.y)}) then
			Msg = move(south pt(x:State.pos.x+1 y:State.pos.y))
		     elseif({CanMove State pt(x:State.pos.x y:State.pos.y-1)}) then
			Msg = move(west pt(x:State.pos.x y:State.pos.y-1))
		     end
		  end
	       end
	    else
	       if ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
		  Msg = move(north pt(x:State.pos.x-1 y:State.pos.y))
	       else
		  if ({InBounds State.pos.x-1 State.pos.y} andthen {List.nth {List.nth Input.map State.pos.x-1} State.pos.y} == 0) then
		     Msg = null
		  else
		     if ({CanMove State pt(x:State.pos.x y:State.pos.y-1)}) then
			Msg = move(west pt(x:State.pos.x y:State.pos.y-1))
		     elseif ({CanMove State pt(x:State.pos.x y:State.pos.y+1)}) then
			Msg = move(east pt(x:State.pos.x y:State.pos.y+1))
		     elseif ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
			Msg = move(south pt(x:State.pos.x+1 y:State.pos.y))
		     end
		  end
	       end
	    end
	 else
	    if (DistX > DistY) then
	       if ((State.pos.x - Xn) < 0) then
		  if ({CanMove State pt(x:State.pos.x+1 y:State.pos.y)}) then
		     Msg = move(south pt(x:State.pos.x+1 y:State.pos.y))
		  else
		     if ({InBounds State.pos.x+1 State.pos.y} andthen {List.nth {List.nth Input.map State.pos.x+1} State.pos.y} == 0) then
			Msg = null
		     else
			if ({CanMove State pt(x:State.pos.x y:State.pos.y-1)}) then
			   Msg = move(west pt(x:State.pos.x y:State.pos.y-1))
			elseif ({CanMove State pt(x:State.pos.x y:State.pos.y+1)}) then
			   Msg = move(east pt(x:State.pos.x y:State.pos.y+1))
			elseif ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
			   Msg = move(north pt(x:State.pos.x-1 y:State.pos.y))
			end
		     end
		  end
	       else
		  if ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
		     Msg = move(north pt(x:State.pos.x-1 y:State.pos.y))
		  else
		     if ({InBounds State.pos.x-1 State.pos.y} andthen {List.nth {List.nth Input.map State.pos.x-1} State.pos.y} == 0) then
			Msg = null
		     else
			if ({CanMove State pt(x:State.pos.x y:State.pos.y-1)}) then
			   Msg = move(west pt(x:State.pos.x y:State.pos.y-1))
			elseif ({CanMove State pt(x:State.pos.x y:State.pos.y+1)}) then
			   Msg = move(east pt(x:State.pos.x y:State.pos.y+1))
			elseif ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
			   Msg = move(south pt(x:State.pos.x+1 y:State.pos.y))
			end
		     end
		  end
	       end
	    else
	       if ((State.pos.x - Xn) < 0) then
		  if ({CanMove State pt(x:State.pos.x y:State.pos.y+1)}) then
		     Msg = move(east pt(x:State.pos.x y:State.pos.y+1))
		  else
		     if ({InBounds State.pos.x State.pos.y+1} andthen {List.nth {List.nth Input.map State.pos.x} State.pos.y+1} == 0) then
			Msg = null
		     else
			if ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
			   Msg = move(north pt(x:State.pos.x-1 y:State.pos.y))
			elseif ({CanMove State pt(x:State.pos.x+1 y:State.pos.y)}) then
			   Msg = move(south pt(x:State.pos.x+1 y:State.pos.y))
			elseif ({CanMove State pt(x:State.pos.x y:State.pos.y-1)} )then
			   Msg = move(west pt(x:State.pos.x y:State.pos.y-1))
			end
		     end
		  end
	       else
		  if ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
		     Msg = move(north pt(x:State.pos.x-1 y:State.pos.y))
		  else
		     if ({InBounds State.pos.x-1 State.pos.y} andthen {List.nth {List.nth Input.map State.pos.x-1} State.pos.y}) == 0 then
			Msg = null
		     else
			if ({CanMove State pt(x:State.pos.x y:State.pos.y-1)}) then
			   Msg = move(west pt(x:State.pos.x y:State.pos.y-1))
			elseif ({CanMove State pt(x:State.pos.x y:State.pos.y+1)}) then
			   Msg = move(east pt(x:State.pos.x y:State.pos.y+1))
			elseif ({CanMove State pt(x:State.pos.x+1 y:State.pos.y)}) then
			   Msg = move(south pt(x:State.pos.x+1 y:State.pos.y))
			end
		     end
		  end
	       end
	    end
	 end*/
         if(DistX > DistY) then
            if(State.pos.x > Xn) then %north
               if ({CanMove State pt(x:State.pos.x-1 y:State.pos.y)}) then
                  Msg = move(north pt(x:State.pos.x-1 y:State.pos.y))
               else
                  Msg = {RandomMove State}
               end
            else %south
               if ({CanMove State pt(x:State.pos.x+1 y:State.pos.y)}) then
                  Msg = move(south pt(x:State.pos.x+1 y:State.pos.y))
               else
                  Msg = {RandomMove State}
               end
            end
         else
            if(State.pos.y > Yn) then %west
               if ({CanMove State pt(x:State.pos.x y:State.pos.y-1)}) then
                  Msg = move(west pt(x:State.pos.x y:State.pos.y-1))
               else
                  Msg = {RandomMove State}
               end
            else %east
               if ({CanMove State pt(x:State.pos.x y:State.pos.y+1)}) then
                  Msg = move(east pt(x:State.pos.x y:State.pos.y+1))
               else
                  Msg = {RandomMove State}
               end
            end
         end
      else
         Msg = {RandomMove State}
      end
      case Msg of null then
	 NewState = {UpdateState State [surf#true visited#[State.visited.1]]}
	 Ret = ret(surface NewState)
      [] move(Dir NewPos) then
	 NewState = {UpdateState State [pos#NewPos visited#(NewPos|State.visited)]}
	 Ret = ret(Dir NewState)
      end
      case Ret of ret(NewDir NewState) then
	 Direction = NewDir
	 Position = NewState.pos
	 ID = NewState.id
      end
      NewState
   end

%%%

   %Donne au Sub la permission de replonger
   fun{Dive State} NewState in
      NewState = {UpdateState State [surf#false]}
      NewState
   end

%%%

   %Donne au Sub la permission de charger un item de son choix
   /*fun{ChargeItem State ID KindItem} NewState in
      if true then %(State.focus == null) then
	 if (State.nextCharge==drone andthen State.droneCharge<Input.drone) then
	    NewState = {UpdateState State [droneCharge#State.droneCharge+1 nextCharge#sonar]}
	    if (NewState.droneCharge == Input.drone) then
	       KindItem = drone
               ID = NewState.id
	    else
	       KindItem = null
               ID = NewState.id
	    end
	 elseif (State.sonarCharge<Input.sonar andthen State.nextCharge==sonar) then
	    if (State.sonarCharge == Input.sonar-1) then
               NewState = {UpdateState State [sonarCharge#State.sonarCharge+1 nextCharge#missile]}
	       KindItem = sonar
               ID = NewState.id
	    else
               NewState = {UpdateState State [sonarCharge#State.sonarCharge+1]}
	       KindItem = null
               ID = NewState.id
	    end
	 elseif (State.missileCharge<Input.missile andthen State.nextCharge==missile) then
	    NewState = {UpdateState State [missileCharge#State.missileCharge+1 nextCharge#drone]}
	    if (NewState.missileCharge == Input.missile) then
	       KindItem = missile
               ID = NewState.id
	    else
	       KindItem = null
               ID = NewState.id
	    end
	 elseif (State.focus \= null) then
	    if (State.missileCharge<Input.missile) then
	       NewState = {UpdateState State [missileCharge#State.missileCharge+1 nextCharge#sonar]}
	       if (NewState.missileCharge == Input.missile) then
		  KindItem = missile
                  ID = NewState.id
	       else
		  KindItem = null
                  ID = NewState.id
	       end
	    end
	 else
	    KindItem = null
            ID = NewState.id
	 end
      else
         NewState = State
         ID = NewState.id
	 KindItem = null
      end
      NewState
   end*/
   fun{ChargeItem State ID KindItem} NewState in
	 if State.missileCharge<Input.missile then
	    NewState = {UpdateState State [missileCharge#State.missileCharge+1]}
	    ID = NewState.id
	    if NewState.missileCharge == Input.missile then
	       KindItem = missile
	    else
	       KindItem = null
	    end
	 elseif State.sonarCharge<Input.sonar then
	    NewState = {UpdateState State [sonarCharge#State.sonarCharge+1]}
	    ID = NewState.id
	    if NewState.sonarCharge == Input.sonar then
	       KindItem = sonar
	    else
	       KindItem = null
	    end
	 elseif State.droneCharge<Input.drone then
	    NewState = {UpdateState State [droneCharge#State.droneCharge+1]}
	    ID = NewState.id
	    if NewState.droneCharge == Input.drone then
	       KindItem = drone
	    else
	       KindItem = null
	    end
	 else
	    NewState = State
	    ID = NewState.id
	    KindItem = null
	 end
	 NewState
   end

%%%

   %Donne au Sub la permission de tirer un item de son choix (missile, sonar, drone)
   fun{FireItem State ID KindFire}
      fun{DistTo Pos1 Pos2}
	 {Number.abs Pos1.x-Pos2.x} + {Number.abs Pos1.y-Pos2.y}
      end
      fun {RandForDrone} R in
	 R = {OS.rand} mod 2
	 case R of 0 then
	    drone(column ({OS.rand} mod Input.nColumn)+1 )
	 [] 1 then
	    drone(row ({OS.rand} mod Input.nRow)+1)
	 end
      end
      fun {PosMi N Pos}
	 if N == 0 then Pos.1
	 else
	    if Pos.2 \= nil then {PosMi N-1 Pos.2}
	    else Pos.1 end
	 end
      end
      NewState
      MPos
   in
   if State.dead then
      KindFire = null
      ID = null
      State
   else
      %{Browser.browse State}
      case State.focus
      of null then
	 if (State.sonarCharge==Input.sonar) then
            %FIRE SONAR
	    KindFire = sonar
	    NewState = {UpdateState State [sonarCharge#0 sonarLaunchOnce#true]}
	 elseif State.droneCharge == Input.drone andthen State.sonarLaunchOnce==true then
            % FIRE DRONE
	    KindFire = {RandForDrone}
	    NewState = {UpdateState State [droneCharge#0]}
	elseif State.missileCharge == Input.missile then
            %FIRE THE MISSILE
	    MPos = {PosMi Input.minDistanceMissile State.visited}
	    if ({DistTo MPos State.pos}>=2 andthen {DistTo MPos State.pos} =< Input.maxDistanceMissile) then
               KindFire = missile(MPos)
	       NewState = {UpdateState State [missileCharge#0]}
	    else
	       NewState = State
	       KindFire = null
	    end
	 else
	    NewState = State
	    KindFire = null
	 end
      []N then
         if State.xsure.N == false then
            KindFire = drone(row ({OS.rand} mod Input.nRow)+1)
            NewState = {UpdateState State [droneCharge#0]}
         elseif State.ysure.N == false then
            KindFire = drone(column ({OS.rand} mod Input.nColumn)+1)
            NewState = {UpdateState State [droneCharge#0]}
	 elseif State.missileCharge == Input.missile andthen {DistTo State.pos State.enemies.N.pos} =< Input.maxDistanceMissile andthen {DistTo State.pos State.enemies.N.pos} >= Input.minDistanceMissile then
            %FIRE THE MISSILE
	    KindFire = missile(State.enemies.N.pos)
	    NewState = {UpdateState State [missileCharge#0]}
	 else
	    NewState = State
	    KindFire = null
	 end
      end
      ID = NewState.id
      NewState
   end
   end

%%%

   %Donne au Sub la permission de tirer une mine
   fun{FireMine State ID Mine}
        ID = State.id
        Mine = null
        State
   end

%%%

   %Demande au Sub s'il est en surface
   fun{IsSurface State ID Answer}
      ID = State.id
      Answer = State.surf
      State
   end

%%%

   % Dit au Sub qu'un Sub a bougé
   % Verif si ne sort pas de la map sinon considere position fausse
   % init focus si sur de position
   fun{SayMove State ID Direction}
      N Pos Npos StateN XS YS StateX StateY StateEn NewState
   in
      N = ID.id
      Pos = State.pos
      if (ID \= State.id) then
         Npos = State.enemies.N.pos
	 if Npos \= null then
	    case Direction of north then
	       if (Npos.x-1) > 0 then %andthen {List.nth {List.nth Input.map Pos.x} Pos.y} == 0 ) then
		  StateN = {UpdateState State.enemies.N [pos#(pt(x:Npos.x-1 y:Npos.y))]}
                  %XS = null
	       else
		  %YS = true
		  %XS = false
                  StateN = {UpdateState State.enemies.N [pos#(pt(x:Npos.x y:Npos.y))]}
	       end
	    [] south then
	       if (Npos.x+1) =< Input.nRow then %andthen {List.nth {List.nth Input.map Pos.x} Pos.y} == 0) then
		  StateN = {UpdateState State.enemies.N [pos#(pt(x:Npos.x+1 y:Npos.y))]}
                  %XS = null
	       else
		  %YS = true
		  %XS = false
                  StateN = {UpdateState State.enemies.N [pos#(pt(x:Npos.x y:Npos.y))]}
	       end
	    [] east then
	       if (Npos.y+1) =< Input.nColumn then %andthen {List.nth {List.nth Input.map Pos.x} Pos.y} == 0) then
		  StateN = {UpdateState State.enemies.N [pos#(pt(x:Npos.x y:Npos.y+1))]}
                  %XS = null
	       else
		  %XS = true
		  %YS = false
                  StateN = {UpdateState State.enemies.N [pos#(pt(x:Npos.x y:Npos.y))]}
	       end
	    [] west then
               if (Npos.y-1) > 0 then %andthen {List.nth {List.nth Input.map Pos.x} Pos.y} == 0) then
		  StateN = {UpdateState State.enemies.N [pos#(pt(x:Npos.x y:Npos.y-1))]}
                  %XS = null
	       else
		  %XS = true
		  %YS = false
                  StateN = {UpdateState State.enemies.N [pos#(pt(x:Npos.x y:Npos.y))]}
	       end
	    end
	    /*if ((XS == true orelse XS == false) andthen N=<Input.nbPlayer) then
               StateX = {UpdateState State.xsure [N#XS]}
               StateY = {UpdateState State.ysure [N#YS]}
	    end*/
	    StateEn = {UpdateState State.enemies [N#StateN]}
	    /*if (XS \= null) then
	       if (State.focus==null) then
		  NewState = {UpdateState State [focus#N enemies#StateEn xsure#StateX ysure#StateY]}
               else
                  NewState = {UpdateState State [enemies#StateEn xsure#StateX ysure#StateY]}
	       end
	    else
	       NewState = {UpdateState State [enemies#StateEn]}
	    end*/
            NewState = {UpdateState State [enemies#StateEn]}
	 else
	    NewState = State
	 end
      else
	 NewState = State
      end
      NewState
   end

%%%

   %Dit au Sub qu'un Sub a fait surface
   fun{SaySurface State ID}
      State
   end

%%%

   %Dit au Sub qu'un Sub a fini de charger un item
   fun{SayCharge State ID KindItem}
      State
   end

%%%

   %Dit au Sub qu'une mine a été placée
   fun{SayMinePlaced State ID}
      State
   end

%%%

   %Annonce l'explosion d'un missile, le Sub doit dire s'il a été touché
   fun{SayMissileExplode State ID Position Message}
      fun{DistToSub Pos1 Pos2}
	 {Number.abs Pos1.x - Pos2.x} + {Number.abs Pos1.y - Pos2.y}
      end
      NewState
      MidState
      Dist
   in
   if State.dead then
      Message = null
      State
   else
      Dist = {DistToSub State.pos Position}
      if Dist == 0 then
	 MidState = {UpdateState State [hp#(State.hp-2)]}
      elseif Dist == 1 then
	 MidState = {UpdateState State [hp#(State.hp-1)]}
      else
	 MidState = State
	 NewState = State
      end
      if State.hp \= MidState.hp then
	 if MidState.hp =< 0 then
	    Message = sayDeath(State.id)
	    NewState = {UpdateState MidState [dead#true hp#0]}
	 else
	    Message = sayDamageTaken(State.id State.hp-MidState.hp MidState.hp)
	    NewState = MidState
	 end
      else
	 Message = null
      end
      NewState
   end
   end

%%%

   %Annonce l'explosion d'une mine, le Sub doit dire s'il a été touché
   fun{SayMineExplode State ID Position Message}
      fun{DistToSub Pos1 Pos2}
	 {Number.abs Pos1.x-Pos2.x} + {Number.abs Pos1.y-Pos2.y}
      end
      NewState
      MidState
      Dist
   in
   if State.dead then
      Message = null
      State
   else
      Dist = {DistToSub State.pos Position}
      if Dist == 0 then
	 MidState = {UpdateState State [hp#(State.hp-2)]}
      elseif Dist == 1 then
	 MidState = {UpdateState State [hp#(State.hp-1)]}
      else
	 MidState = State
	 NewState = State
      end
      if State.hp \= MidState.hp then
	 if MidState.hp =< 0 then
	    Message = sayDeath(State.ID)
	    NewState = {UpdateState MidState [dead#true hp#0]}
	 else
	    Message = sayDamageTaken(State.ID State.hp-MidState.hp MidState.hp)
	    NewState = MidState
	 end
      else
	 Message = null
      end
      NewState
   end
   end

%%%

   %Annonce le passage d'un drone, le Sub doit y répondre
   fun{SayPassingDrone State Drone ID Answer}
   if State.dead then
      Answer = null
      ID = null
      State
   else
      case Drone
      of drone(row X) then
	 if State.pos.x == X then
	    Answer = true
	 else
	    Answer = false
	 end
      [] drone(column Y) then
	 if State.pos.y == Y then
	    Answer = true
	 else
	    Answer = false
	 end
      end
      ID = State.id
      State
   end
   end

%%%

   %Réponse au drone que l'on a lancé
   fun{SayAnswerDrone State Drone ID Answer}
   if State.dead orelse ID == null then
      Answer = null
      ID = null
      State
   else
      StateN StateEn NewState StateX StateY N Npos in
      N = ID.id
      Npos = State.enemies.N.pos
      case Drone
      of drone(row X) then
	 if Answer == true then
	    if N \= State.id.id then
	       StateX = {UpdateState State.xsure [N#true]}
               StateN = {UpdateState State.enemies.N [pos#(pt(x:X y:Npos.y))]}
	       StateEn = {UpdateState State.enemies [N#StateN] }
	       NewState = {UpdateState State [enemies#StateEn xsure#StateX]}
            else
               NewState = State
	    end
	 else
            if X == Npos.x then
               StateX = {UpdateState State.xsure [N#false]}
               NewState = {UpdateState State [xsure#StateX]}
            else
               NewState = State
            end
	 end
      []drone(column Y) then
	 if Answer == true then
	    if N \= State.id.id then
	       StateY = {UpdateState State.ysure [N#true]}
	       StateN = {UpdateState State.enemies.N [pos#(pt(x:Npos.x y:Y))]}
	       StateEn = {UpdateState State.enemies [N#StateN] }
	       NewState = {UpdateState State [enemies#StateEn ysure#StateY]}
            else
               NewState = State
            end
	 else
            if Y == Npos.y then
               StateY = {UpdateState State.ysure [N#false]}
               NewState = {UpdateState State [ysure#StateY]}
            else
               NewState = State
            end
	 end
      end
      NewState
   end
   end

%%%

   %Annonce le passage d'un sonar, le Sub doit y répondre
   fun{SayPassingSonar State ID Answer}
   if State.dead then
      Answer = null
      ID = null
      State
   else
      ID = State.id
      %On donnera la position x exacte, mais la mauvaise position y (random), par exemple
      %Answer = pt(x:State.pos.x y:({OS.rand} mod Input.nColumn + 1))
      Answer = State.pos
      State
   end
   end

%%%

   %Réponse au sonar que l'on a lancé
   fun{SayAnswerSonar State ID Answer} StateN StateEn NewState N X Y in
      N = ID.id
      if N \= State.id then
	 StateN = {UpdateState State.enemies.N [pos#Answer]}
	 StateEn = {UpdateState State.enemies [N#StateN]}
	 if State.xsure.N \= true then
	    X = {UpdateState State.xsure [N#false]}
	 end
	 if State.ysure.N \= true then
	    Y = {UpdateState State.ysure [N#false]}
	 end
	 NewState = {UpdateState State [enemies#StateEn xsure#X ysure#Y focus#N]}
      else
	 NewState = State
      end
      NewState
   end

%%%

   %Dit au Sub qu'un Sub est mort
   fun{SayDeath State ID} StateEn X Y NewState in
      StateEn = {Record.subtract State.enemies ID}
      X = {Record.subtract State.xsure ID}
      Y = {Record.subtract State.ysure ID}
      if State.focus\= null andthen State.focus == ID then
	 NewState = {UpdateState State [enemies#StateEn focus#null X Y]}
      else
	 NewState = {UpdateState State [enemies#StateEn X Y]}
      end
      NewState
   end

%%%

   %Dit au Sub qu'un Sub a pris des dégâts
   fun{SayDamageTaken State ID Damage LifeLeft}
      %Ne rien faire on ne fait pas attention au hp des autres
      State
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{StartPlayer Color ID}
      Stream
      Port
      State
   in
      Port = {NewPort Stream}
      thread
	 State = {InitState ID Color}
	 {TreatStream Stream State}
      end
      Port
   end

   proc{TreatStream Stream State}
      %{Browser.browse Stream.1}
      case Stream
      of nil then skip
      []initPosition(ID Position)|S then NewState in
	 NewState = {InitPosition State ID Position}
	 {TreatStream S NewState}
      []move(ID Position Direction)|S then NewState in
	 NewState = {Move State ID Position Direction}
	 {TreatStream S NewState}
      []dive|S then NewState in
	 NewState = {Dive State}
	 {TreatStream S NewState}
      []chargeItem(ID KindItem)|S then NewState in
	 NewState = {ChargeItem State ID KindItem}
	 {TreatStream S NewState}
      []fireItem(ID KindFire)|S then NewState in
	 NewState = {FireItem State ID KindFire}
	 {TreatStream S NewState}
      []fireMine(ID Mine)|S then NewState in
	 NewState = {FireMine State ID Mine}
	 {TreatStream S NewState}
      []isSurface(ID Answer)|S then NewState in
	 NewState = {IsSurface State ID Answer}
	 {TreatStream S NewState}
      []sayMove(ID Direction)|S then NewState in
	 NewState = {SayMove State ID Direction}
	 {TreatStream S NewState}
      []saySurface(ID)|S then NewState in
	 NewState = {SaySurface State ID}
	 {TreatStream S NewState}
      []sayCharge(ID KindItem)|S then NewState in
	 NewState = {SayCharge State ID KindItem}
	 {TreatStream S NewState}
      []sayMinePlaced(ID)|S then NewState in
	 NewState = {SayMinePlaced State ID}
	 {TreatStream S NewState}
      []sayMissileExplode(ID Position Message)|S then NewState in
	 NewState = {SayMissileExplode State ID Position Message}
	 {TreatStream S NewState}
      []sayMineExplode(ID Position Message)|S then NewState in
	 NewState = {SayMineExplode State ID Position Message}
	 {TreatStream S NewState}
      []sayPassingDrone(Drone ID Answer)|S then NewState in
	 NewState = {SayPassingDrone State Drone ID Answer}
	 {TreatStream S NewState}
      []sayAnswerDrone(Drone ID Answer)|S then NewState in
	 NewState = {SayAnswerDrone State Drone ID Answer}
	 {TreatStream S NewState}
      []sayPassingSonar(ID Answer)|S then NewState in
	 NewState = {SayPassingSonar State ID Answer}
	 {TreatStream S NewState}
      []sayAnswerSonar(ID Answer)|S then NewState in
	 NewState = {SayAnswerSonar State ID Answer}
	 {TreatStream S NewState}
      []sayDeath(ID)|S then NewState in
	 NewState = {SayDeath State ID}
	 {TreatStream S NewState}
      []sayDamageTaken(ID Damage LifeLeft)|S then NewState in
	 NewState = {SayDamageTaken State ID Damage LifeLeft}
	 {TreatStream S NewState}
      else
	 skip
      end
   end
end
