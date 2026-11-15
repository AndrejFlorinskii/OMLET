within OMLET.Basic.Generators;
model SM_EMF_Form
  "Синхронная машина в форме ЭДС (Рустаб-стиль)"
  outer SysData sysData;

  // PQ-diagram parameter
  parameter OMLET.Data.PQ_CapabilityTable pq_table=OMLET.Data.TVV_500_2;

  parameter Boolean inService_G = true "Generator topological condition"
  annotation(Dialog(tab="General"));
  parameter Real TgenOff=1000 "Time of generator's disconnection, s"
   annotation(Dialog(tab="General"));
  parameter Real dTgenOff=10 "Duration of generator's disconnection, s"
   annotation(Dialog(tab="General"));
  parameter Real Kd=0 "damping coefficient"
  annotation(Dialog(tab="Synchronous machine"));

  //------------------------------------------------------------------------------------
  parameter Real Sbaz=sysData.Sbaz "Bazic power, MWA"
   annotation(Dialog(tab="General"));
  parameter Real fbaz=sysData.fbaz "Bazic frequency, Hz"
   annotation(Dialog(tab="General"));
  parameter Real Pg=500 "Active power, MW"
   annotation(Dialog(tab="General"));
  parameter Real Qg(fixed=false) "Reactive power, MVAR";
  parameter Real Ut=20 "ARV voltage reference value, kV"
   annotation(Dialog(tab="General"));
  parameter Real Pnom=500 "Nominal maschine active power, MW"
   annotation(Dialog(tab="General"));
  parameter Real Ugnom=20 "Nominal stator voltage, kV"
   annotation(Dialog(tab="General"));
  parameter Real cosfi_nom=0.85 "Nominal maschine power coefficient, p.u."
   annotation(Dialog(tab="General"));
  parameter Real Ignom(fixed=false) "stator nomunal current, kA";

   // Limitation variables
  Real Qmax "Current limit of overexcitation, MVar";
  Real Qmin "Current limit of underexcitation, MVar";

  Real P_clipped_max;
  Real P_clipped_min;
  Integer i_max_dummy;
  Integer i_min_dummy;

  //------------------------------------------------------------------------------------
  parameter Real Xd_p=1.869 "D-axis synchronous reactance, p.u."
   annotation(Dialog(tab="Synchronous machine"));
  parameter Real Xq_p=1.869 "Q-axis synchronous reactance, p.u."
   annotation(Dialog(tab="Synchronous machine"));
  parameter Real Xs_p=0.194 "Leakage reactance of stator winding, p.u."
   annotation(Dialog(tab="Synchronous machine"));
  parameter Real X1d_p=0.3016 "D-axis transient reactance, p.u."
   annotation(Dialog(tab="Synchronous machine"));
  parameter Real X2d_p=0.2337 "D-axis subtransient reactance, p.u."
   annotation(Dialog(tab="Synchronous machine"));
  parameter Real X2q_p=0.2337 "Q-axis subtransient reactance, p.u."
   annotation(Dialog(tab="Synchronous machine"));

  Real Xad "D-axis resistance to mutual induction";

  parameter Real Tj_p=7 "Inertia coefficient, s"
   annotation(Dialog(tab="Synchronous machine"));
  parameter Real Td0=10 "D-axis transient time constant, s"
   annotation(Dialog(tab="Synchronous machine"));
  parameter Real T2d_p=0.02 "D-axis subtransient time constant, s"
   annotation(Dialog(tab="Synchronous machine"));
  parameter Real T2q_p=0.05 "Q-axis subtransient time constant, s"
   annotation(Dialog(tab="Synchronous machine"));

  parameter Real TregOff=50 "Turbine speed regulator off-time, s"
   annotation(Dialog(tab="Turbine"));
  parameter Real Mtmax=1.1 "Turbine overloading coefficient, p.u."
   annotation(Dialog(tab="Turbine"));
  parameter Real Mtmin=0 "Turbine minimum-loading coefficient, p.u."
   annotation(Dialog(tab="Turbine"));
  parameter Real TkzOn=1000 "Generators dropping on-time, s"
   annotation(Dialog(tab="General"));
  parameter Real Pg_new=100 "New power of power plant, MW"
   annotation(Dialog(tab="General"));

  //------------------------------------------------------------------------------------
  Real dUtr, dWu, dIf, dWf;
  Real Er;
  constant Real PI=4*atan(1);
  parameter Real Wc=2*PI*fbaz;
  parameter Real Xt=0.0;

  constant Real Ra=0;
  constant Real Rt=0;
  parameter Real EQ(fixed=false);
  parameter Real Dg(fixed=false);
  parameter Real Uq(fixed=false);
  parameter Real Ud(fixed=false);
  parameter Real Id(fixed=false);
  parameter Real Iq(fixed=false);
  parameter Real Er0(fixed=false);
  parameter Real Ir(fixed=false);

  Real Ugen, Igen;
  parameter Real Mu0(fixed=false);
  Real Mt_pp, Pgen, Qgen, UdG, UqG, IdG, IqG;
  input Real DeltaIJ;
  input Real Ssys;

  // Integrated Variables (ЭДС вместо потоков)
  Real Eqp "Transient EMF E'q";
  Real Eqpp "Subtransient EMF E''q";
  Real Edpp "Subtransient EMF E''d";
  Real s "generator slip";
  Real DGi "Generator power angle";
  Real Me "electrical moment";

  Real id, iq, ud, uq, ir;
  Real MT_MAX, MT_MIN;
  Real Xd, Xq, Xs, X1d, X2d, X2q, Tj, f;

  parameter Real Ut_pu(fixed=false);
  parameter Real Pg_pu(fixed=false);
  parameter Real Qg_pu(fixed=false);

  OMLET.Interfaces.Pin_v2 Stator_pin annotation (extent=[68,-8; 88,12],
      Placement(transformation(extent={{90,-10},{110,10}}, rotation=0),
        iconTransformation(extent={{90,-10},{110,10}})));
  OMLET.Interfaces.Signal_pin Ef_pin annotation (extent=[-90,-8; -70,12],
      Placement(transformation(extent={{-110,-10},{-90,10}}, rotation=0),
        iconTransformation(extent={{-110,-10},{-90,10}})));
  OMLET.Interfaces.Signal_pin dUtr_pin annotation (
    extent=[-60,66; -40,86],
    layer="icon",
    Placement(transformation(extent={{-64,90},{-44,110}}, rotation=0),
        iconTransformation(extent={{-64,90},{-44,110}})));
  OMLET.Interfaces.Signal_pin dWu_pin annotation (
    extent=[-26,66; -6,86],
    layer="icon",
    Placement(transformation(extent={{-36,90},{-16,110}}, rotation=0),
        iconTransformation(extent={{-36,90},{-16,110}})));
  OMLET.Interfaces.Signal_pin dWf_pin annotation (
    extent=[6,66; 26,86],
    layer="icon",
    Placement(transformation(extent={{-10,90},{10,110}}, rotation=0),
        iconTransformation(extent={{-10,90},{10,110}})));
  OMLET.Interfaces.Signal_pin dIf_pin annotation (
    extent=[40,66; 60,86],
    layer="icon",
    Placement(transformation(extent={{18,90},{38,110}}, rotation=0),
        iconTransformation(extent={{18,90},{38,110}})));
  OMLET.Interfaces.Signal_pin Ut_pin annotation (Placement(transformation(
          extent={{46,90},{66,110}}), iconTransformation(extent={{46,90},
            {66,110}})));
  Interfaces.Signal_pin       Er0_pin
    annotation (Placement(transformation(extent={{70,90},{90,110}}),
        iconTransformation(extent={{70,90},{90,110}})));
  Interfaces.Signal_pin       Ugen_pin
    annotation (Placement(transformation(extent={{-90,90},{-70,110}}),
        iconTransformation(extent={{-90,90},{-70,110}})));
  Interfaces.Signal_pin dIg_pin annotation (Placement(transformation(extent={{94,90},
            {114,110}}),     iconTransformation(extent={{94,90},{114,110}})));
  Interfaces.Signal_pin slip_pin annotation (Placement(transformation(extent={{-110,
            30},{-90,50}}), iconTransformation(extent={{-110,30},{-90,50}})));
  Interfaces.Signal_pin Mu0_pin annotation (Placement(transformation(extent={{-110,66},
            {-90,86}}),       iconTransformation(extent={{-110,66},{-90,86}})));
  Interfaces.Signal_pin Mt_pin annotation (Placement(transformation(extent={{-110,
            66},{-90,86}}), iconTransformation(extent={{-110,-48},{-90,-28}})));
initial equation
  // additional variables in p.u.
  Ut_pu = Ut/Ugnom;
  Pg_pu = Pg/Sbaz;
  Qg_pu = Qg/Sbaz;
  Ignom = Pnom/cosfi_nom/sqrt(3)/Ugnom;

  // equations of currents, voltages, and flux densities
  s = 0;

  EQ = sqrt((Ut_pu + ((Ra + Rt)*Pg_pu + (Xq + Xt)*Qg_pu)/Ut_pu)^2 + (((Xq + Xt)*Pg_pu - (Ra + Rt)*Qg_pu)/Ut_pu)^2);
  Dg = atan((((Xq + Xt)*Pg_pu - (Ra + Rt)*Qg_pu)/Ut_pu)/(Ut_pu + ((Ra + Rt)*Pg_pu + (Xq + Xt)*Qg_pu)/Ut_pu));

  Uq = Ut_pu*cos(Dg);
  Ud = -Ut_pu*sin(Dg);

  Er0  = Eqp - Id*(Xd - X1d);
  Ir = Er0/Xad;

  if inService_G then
    Qg=min(Qmax, max(Qmin, Qgen));
    Pg=Pgen;
    Id = ((Uq - EQ)*(Xq + Xt) - (Ra + Rt)*Ud)/((Ra + Rt)^2 + (Xq + Xt)^2);
    Iq = (-Ud - (Ra + Rt)*Id)/(Xq + Xt);
    Mu0 = EQ*Iq;
    DGi = Dg;
    Eqpp = Uq - Id*X2d;
    Edpp = Ud + Iq*X2q;
    Eqp  = Eqpp - Id*(X1d - X2d);
  else
    Qg=0;
    Id = 0;
    Iq = 0;
    Mu0 = 0;
    DGi = 0;
    Eqpp = 0;
    Edpp = 0;
    Eqp  = 0;
  end if;

equation
  P_clipped_max = max(pq_table.P_max[1], min(Pgen, pq_table.P_max[end]));
  P_clipped_min = max(pq_table.P_min[1], min(Pgen, pq_table.P_min[end]));

  (Qmax, i_max_dummy) = Modelica.Math.Vectors.interpolate(pq_table.P_max, pq_table.Qmax, P_clipped_max);
  (Qmin, i_min_dummy) = Modelica.Math.Vectors.interpolate(pq_table.P_min, pq_table.Qmin, P_clipped_min);

  // Пересчет параметров на системную базу
  Xad = Xd - Xs;

  Xd  = if time < TkzOn then Xd_p*Sbaz/Pnom*cosfi_nom else Xd_p*Sbaz/Pnom*cosfi_nom*Pg/Pg_new;
  Xq  = if time < TkzOn then Xq_p*Sbaz/Pnom*cosfi_nom else Xq_p*Sbaz/Pnom*cosfi_nom*Pg/Pg_new;
  Xs  = if time < TkzOn then Xs_p*Sbaz/Pnom*cosfi_nom else Xs_p*Sbaz/Pnom*cosfi_nom*Pg/Pg_new;
  X1d = if time < TkzOn then X1d_p*Sbaz/Pnom*cosfi_nom else X1d_p*Sbaz/Pnom*cosfi_nom*Pg/Pg_new;
  X2d = if time < TkzOn then X2d_p*Sbaz/Pnom*cosfi_nom else X2d_p*Sbaz/Pnom*cosfi_nom*Pg/Pg_new;
  X2q = if time < TkzOn then X2q_p*Sbaz/Pnom*cosfi_nom else X2q_p*Sbaz/Pnom*cosfi_nom*Pg/Pg_new;
  Tj  = if time < TkzOn then Tj_p*Pnom/Sbaz else Tj_p*Pnom/Sbaz*Pg_new/Pg;

  // --- ДИФФЕРЕНЦИАЛЬНЫЕ УРАВНЕНИЯ МОДЕЛИ ПГО (РУСТАБ) ---
  Td0*der(Eqp) = Er - Eqp + id*(Xd - X1d);
  T2d_p*der(Eqpp) = Eqp - Eqpp + id*(X1d - X2d);
  T2q_p*der(Edpp) = -Edpp - iq*(Xq - X2q);

  der(DGi) = Wc*s;
  der(s)   = (Mt_pp/(1+s) - Me/(1+s) - Kd/2*s)/Tj;

  MT_MIN = if time < TkzOn then Mtmin*Pg_pu else Pg_new/Sbaz - 0.01;
  MT_MAX = if time < TkzOn then Mtmax*Pg_pu else Pg_new/Sbaz + 0.01;

  // --- АЛГЕБРАИЧЕСКИЕ СВЯЗИ СТАТОРА И ТОКОВ ---
  id = if not inService_G then 0 else if time >= TgenOff and time < TgenOff + dTgenOff then 0 else (uq - Eqpp)/X2d;
  iq = if not inService_G then 0 else if time >= TgenOff and time < TgenOff + dTgenOff then 0 else (-ud + Edpp)/X2q;
  ir = if not inService_G then 0 else if time >= TgenOff and time < TgenOff + dTgenOff then 0 else (Eqp - id*(Xd - X1d))/Xad;

  Me = Eqpp*iq + Edpp*id + (X2d - X2q)*id*iq;

  Ugen = (sqrt(ud^2 + uq^2))*Ugnom;
  Igen = (sqrt(IqG^2 + IdG^2))*Sbaz/sqrt(3)/Ugnom;
  dUtr = sqrt(ud^2 + uq^2) - Ut_pu;
  dWu  = Wc*Ssys; // Ssys приходит извне как input
  dWf  = if UqG > 0.0 or UqG < 0.0 then atan2(UdG, UqG) else atan2(UdG, 0.001);
  dIf  = (ir - Ir)*Xad;

  Pgen = (uq*iq + ud*id)*Sbaz;
  Qgen = (-uq*id + ud*iq)*Sbaz;

  // Связь осей ротора и сети через DeltaIJ (приходит извне как input)
  uq = UqG*cos(DeltaIJ) - UdG*sin(DeltaIJ);
  ud = UqG*sin(DeltaIJ) + UdG*cos(DeltaIJ);

  IqG = iq*cos(DeltaIJ) + id*sin(DeltaIJ);
  IdG = id*cos(DeltaIJ) - iq*sin(DeltaIJ);

  f = Wc*(1-s)/2/PI;

  //--Stator--
  Stator_pin.Vd = UdG;
  Stator_pin.Vq = UqG;

  Stator_pin.Id = IdG;
  Stator_pin.Iq = IqG;

  //---input-rotor--field--voltage---
  Er = Ef_pin.Signal;

  //----to--excitation--system---
  dUtr_pin.Signal = dUtr;
  dWu_pin.Signal = dWu;
  dWf_pin.Signal = dWf;
  dIf_pin.Signal = dIf;
  Ut_pin.Signal = Ut_pu;
  Er0_pin.Signal = Er0;
  Ugen_pin.Signal = sqrt(ud^2 + uq^2);
  dIg_pin.Signal = sqrt(IqG^2 + IdG^2) - sqrt(Id^2 + Iq^2);

  Mt_pp = max(MT_MIN, min(MT_MAX,Mt_pin.Signal))  "таким хитрым образом выбирается сигнал с регулятора, если он не ограничен Mtmax, Mtmin";
  slip_pin.Signal = if time >= TregOff then 0 else s;
  Mu0 = Mu0_pin.Signal;

  annotation (
    Coordsys(
      extent=[-100, -100; 100, 100],
      grid=[2, 2],
      component=[20, 20]),
    Window(
      x=0.06,
      y=0.07,
      width=0.6,
      height=0.77),
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        preserveOrientation=false,
        extent={{-100,-100},{100,100}},
        grid={2,2},
        initialScale=0), graphics),
    Icon(
      coordinateSystem(
        preserveAspectRatio=false,
        preserveOrientation=false,
        extent={{-100,-100},{100,100}},
        grid={2,2},
        initialScale=0),
      graphics={
        Ellipse(
          extent={{-66,66},{70,-64}},
          lineColor={0,0,255},
          lineThickness=1),
        Text(extent={{-36,36},{40,-38}},  textString=
                                               "SM"),
        Text(extent={{-74,-56},{86,-98}},
          textColor={0,0,0},
          textString="%name"),
        Line(
          points={{-66,0},{-94,0}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{96,0},{70,0}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{-46,48},{-54,60},{-54,94}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{-26,60},{-26,96}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{0,66},{0,98}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{48,48},{56,60},{56,94}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{28,62},{28,94}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{62,32},{80,58},{80,92}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{-60,30},{-80,58},{-80,92}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{70,12},{104,58},{104,92}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{-64,14},{-98,40}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{-64,-14},{-100,-42}},
          color={0,0,255},
          thickness=1),
        Line(
          points={{-80,58},{-98,76}},
          color={0,0,255},
          thickness=1)},
      Ellipse(extent=[-60, 62; 60, -58], style(thickness=2)),
      Text(extent=[-38, 38; 38, -36], string="SM"),
      Text(extent=[-80, -58; 80, -100], string="%name"),
      Line(points=[-60, 2; -72, 2], style(thickness=2)),
      Line(points=[70, 2; 60, 2], style(thickness=2))),
              __Dymola_Commands(editCall=plot(
            {"L0709_1.P1","L0709_1.U1m"},
            legends={"Calibration L0709_1.P1","Calibration L0709_1.U1m"},
            colors={{255,0,0},{255,0,0}}) "Calibration_U"), Documentation(
        info="<html>
<p>Synchronous generator without exciter model. </p>
<p>Модель синхронного генератора с исключенным возбудителем. </p>
</html>"));
end SM_EMF_Form;
