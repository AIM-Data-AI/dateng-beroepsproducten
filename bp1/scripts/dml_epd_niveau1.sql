-- =============================================================================
-- DML: EPD Insert Data for ICU Patients - BP1
-- Generated: 2026-05-11
--
-- Description:
--   Realistic patient data for 20 ICU patients, covering a range of common
--   intensive-care diagnoses. Patient IDs are non-sequential (randomly assigned)
--   to avoid any implied ranking or ordering.
--
--   Tables populated:
--     1. patient            - demographics and primary treatment
--     2. patient_observation - first ICU clinical note with pain score
--
--   The note_ts timestamp in patient_observation marks the start of the
--   30-minute ICU machine monitoring window used in icu_data.csv.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. patient
-- -----------------------------------------------------------------------------

INSERT INTO patient (pid, firstname, lastname, dob, treatment) VALUES
-- Post-cardiac surgery: transferred from OR after coronary bypass
(13847, 'Jan',     'de Vries',     '1965-03-12', 'Post-operative care: Coronary Artery Bypass Grafting (CABG x3)'),

-- Septic shock: haemodynamically unstable on vasopressors post-laparotomy
(11256, 'Maria',   'Jansen',       '1978-07-24', 'Septic shock secondary to perforated diverticulitis (post-Hartmann procedure)'),

-- ARDS: proned for severe hypoxaemia in COVID-19 pneumonia
(17291, 'Pieter',  'Bakker',       '1955-11-08', 'Acute Respiratory Distress Syndrome (ARDS) secondary to COVID-19 pneumonia'),

-- Traumatic brain injury: bifrontal contusions with raised ICP
(14538, 'Anna',    'Visser',       '1982-06-15', 'Severe traumatic brain injury (GCS 8) - bifrontal contusions and subdural haematoma'),

-- Multi-organ failure: cardiogenic shock with AKI and elevated liver enzymes
(19012, 'Klaas',   'Smit',         '1949-02-28', 'Multi-organ failure secondary to cardiogenic shock (EF 15%)'),

-- Post-abdominal surgery: emergency laparotomy for perforated peptic ulcer
(12673, 'Sophie',  'Meijer',       '1990-09-03', 'Post-operative care: Emergency laparotomy for perforated peptic ulcer'),

-- Acute myocardial infarction: anterior STEMI post-primary PCI
(16184, 'Hendrik', 'Mulder',       '1960-05-19', 'Anterior STEMI (LAD occlusion) - post-primary PCI with drug-eluting stent'),

-- Ischaemic stroke: right MCA territory, thrombolysis administered
(18350, 'Lisa',    'Bos',          '1974-12-01', 'Ischaemic stroke - right MCA territory, IV thrombolysis (alteplase) administered'),

-- Severe pancreatitis: 60% pancreatic necrosis, aggressive fluid resuscitation
(11729, 'Willem',  'Groot',        '1967-04-22', 'Severe acute pancreatitis with 60% pancreatic necrosis'),

-- Acute renal failure: AKI stage 3 on CVVH, no active blood loss
(15463, 'Emma',    'de Boer',      '1985-08-16', 'Acute kidney injury (AKI stage 3) secondary to contrast nephropathy - CVVH commenced'),

-- Opioid overdose: respiratory depression, partial naloxone response
(13091, 'Thomas',  'van den Berg', '1993-01-30', 'Opioid (heroin) overdose with respiratory depression - intubated for airway protection'),

-- Burns: 42% TBSA flame burns with inhalation injury
(17824, 'Lena',    'Dijkstra',     '1988-10-07', 'Flame burns 42% TBSA (mixed partial/full thickness) with inhalation injury'),

-- Post-liver transplant: POD1, immunosuppression commenced
(12516, 'Martijn', 'Hendriks',     '1971-07-11', 'Post-operative care: Orthotopic liver transplantation for end-stage liver disease (MELD 28)'),

-- Diabetic ketoacidosis: severe DKA with hypokalaemia and dehydration
(19347, 'Noor',    'Vliet',        '2000-03-25', 'Diabetic ketoacidosis (DKA) with severe dehydration and hypokalaemia'),

-- Pneumonia with respiratory failure: no active blood loss
(14102, 'Frank',   'Molenaar',     '1952-09-17', 'Community-acquired pneumonia with type 2 respiratory failure - intubated and ventilated'),

-- Upper GI bleed: bleeding peptic ulcer, dual endoscopic therapy, transfused
(16758, 'Rosa',    'Laan',         '1969-11-29', 'Massive upper GI haemorrhage - bleeding peptic ulcer (Forrest Ia), post-endoscopic haemostasis'),

-- Pulmonary embolism: bilateral saddle PE, post-systemic thrombolysis
(11893, 'Dirk',    'van Dijk',     '1977-02-14', 'Massive pulmonary embolism (bilateral saddle) - post-systemic thrombolysis (alteplase)'),

-- Bacterial meningitis: Neisseria meningitidis confirmed on CSF PCR
(15024, 'Hanna',   'de Jong',      '1995-06-08', 'Bacterial meningitis (Neisseria meningitidis) with petechial rash and haemodynamic compromise'),

-- Post-thoracic surgery: right lower lobectomy for NSCLC, epidural analgesia
(18436, 'Joost',   'Vermeer',      '1963-08-23', 'Post-operative care: Right lower lobectomy for stage II non-small-cell lung cancer'),

-- Hypertensive crisis: BP 230/140 with hypertensive encephalopathy (PRES)
(13615, 'Ingrid',  'Kuiper',       '1957-04-05', 'Hypertensive emergency with acute hypertensive encephalopathy (PRES confirmed on CT)');


-- -----------------------------------------------------------------------------
-- 2. patient_observation
--
--    poid     : unique observation identifier (11001-11020; reserved 11000-11999
--               block, distinct from bp1's own pid range 10000-19999, so it
--               doesn't need renumbering when merged into bp3)
--    pid      : foreign key to patient.pid
--    note_ts  : datetime of the clinical note; doubles as the start of the
--               30-minute ICU machine monitoring window
--    note_text: structured ICU admission / status note
--    pain_score: 0-10 NRS; sedated/unconscious patients score 0-2
-- -----------------------------------------------------------------------------

INSERT INTO patient_observation (poid, pid, note_ts, note_text, pain_score) VALUES

(11001, 13847, '2026-05-11 08:00:00',
 'Patient transferred from OR after uncomplicated CABG x3 (LIMA-LAD, SVG-OM, SVG-RCA). Haemodynamically stable. Intubated and sedated with propofol TCI + remifentanil. Chest drains in situ, minimal haemoserous output. ECG: sinus rhythm 88 bpm, no new ST changes. Plan: wean sedation, extubate when extubation criteria met (FiO2 <=0.4, PEEP <=5, spontaneous effort). IV analgesia: paracetamol 1g q6h + morphine PCA post-extubation.',
 6),

(11002, 11256, '2026-05-11 07:30:00',
 'Post-operative day 1 following emergency Hartmann procedure for perforated diverticulitis. Septic shock ongoing: norepinephrine 0.15 mcg/kg/min to maintain MAP >65 mmHg. Lactate 3.8 mmol/L (was 5.2 on admission - improving). Broad-spectrum antibiotics: piperacillin/tazobactam 4.5g q6h + metronidazole 500mg q8h. WBC 22.1 x10^9/L. Haemodynamic targets: CVP 8-12, MAP >65. Fluid balance: +1800 ml last 24h. Drain output 85 ml/hr (cloudy). Nutrition via NGT (Nutrison Protein Plus).',
 5),

(11003, 17291, '2026-05-11 09:15:00',
 'ARDS secondary to COVID-19 pneumonia. Day 6 on ICU. Berlin criteria: severe (P/F ratio 98 on PEEP 14, FiO2 0.65). Prone positioning 16 hours/day - currently prone. Neuromuscular blockade: cisatracurium infusion (48h course). Deep sedation: RASS -4. Lung-protective ventilation: Vt 6 ml/kg IBW, plateau pressure 26 cmH2O, driving pressure 12 cmH2O. Renal function stable (creatinine 102). Nutritional support: 2200 kcal/day via NGT. CRP 245 (improving). Steroids: dexamethasone 6mg OD.',
 3),

(11004, 14538, '2026-05-11 06:45:00',
 'Severe TBI following high-speed motor vehicle accident. GCS 8 (E2V2M4) on admission. CT head: bifrontal contusions, right acute subdural haematoma (5mm), no midline shift. ICP monitoring (Codman bolt) in situ: ICP 22 mmHg, CPP 68 mmHg. ICP management: head elevation 30 degrees, osmotherapy (mannitol 20% 100ml PRN ICP >25), sedation (propofol + fentanyl). Pupils: equal, 3mm, reactive. Neurosurgery review: conservative management for now, repeat CT in 6 hours. Temperature management: target normothermia.',
 2),

(11005, 19012, '2026-05-11 10:00:00',
 'Multi-organ failure: cardiogenic shock (EF 15% on TTE), AKI stage 3 (creatinine 620 umol/L), transaminitis (ALT 892, AST 1024). IABP in situ (1:1 counterpulsation). Vasopressor support: norepinephrine 0.25 mcg/kg/min + dobutamine 5 mcg/kg/min. Intubated: lung-protective ventilation. CVVH commenced (femoral Vascath) targeting euvolaemia. Cardiology: considering ECMO if haemodynamics deteriorate. Full metabolic workup pending. Prognosis discussed with family.',
 7),

(11006, 12673, '2026-05-11 08:30:00',
 'Post-operative day 0. Emergency laparotomy 4 hours ago for perforated peptic ulcer with generalised peritonitis. Graham patch repair performed, peritoneal washout x4 litres. Currently intubated (deep sedation: propofol + fentanyl infusion). NG tube in situ, free drainage. Right-sided drain output 120 ml/hr serosanguineous. Antibiotics: cefuroxime 1.5g TDS + metronidazole 500mg TDS. FBC: Hb 91, WBC 18.6, Plt 312. Lactate 2.4 mmol/L. Plan: ICU overnight, aim for extubation tomorrow if cardiovascularly stable.',
 8),

(11007, 16184, '2026-05-11 07:00:00',
 'Anterior STEMI. Primary PCI to LAD performed 2 hours ago (door-to-balloon 42 min). Drug-eluting stent deployed in mid-LAD, TIMI 3 flow restored. Post-procedure ECG: resolving ST elevation V2-V5. Troponin T 4320 ng/L (rising). Echo (post-PCI): anterior wall hypokinesis, EF 45%, no significant MR or pericardial effusion. Dual antiplatelet: aspirin 75mg OD + ticagrelor 90mg BD. Anticoagulation: unfractionated heparin infusion (therapeutic). ACE inhibitor and beta-blocker commenced at low dose. Cardiology follow-up arranged.',
 7),

(11008, 18350, '2026-05-11 11:00:00',
 'Right MCA ischaemic stroke with left hemiparesis. NIHSS 14. IV thrombolysis (alteplase 0.9 mg/kg) administered at 2.5 hours from symptom onset. CT perfusion: large ischaemic penumbra, small core. Mechanical thrombectomy considered - interventional radiology review pending. BP management: permissive hypertension target <180/105 mmHg. Neurological observations q1h. Swallow assessment deferred. Aspirin deferred 24h post-thrombolysis. DVT prophylaxis: TED stockings only. Admission to stroke unit after ICU stabilisation.',
 4),

(11009, 11729, '2026-05-11 09:00:00',
 'Severe acute pancreatitis (Ranson score 5, APACHE II 18). CT abdomen (CECT): 60% pancreatic necrosis (Balthazar grade E). Aggressive IV fluid resuscitation: Hartmann''s 250 ml/hr (total 4200 ml last 16h). Nil by mouth. TPN commenced (2000 kcal, 1.5g protein/kg/day). Analgesia: morphine PCA 1mg bolus + paracetamol 1g q6h. WBC 18.2, CRP 312, lipase 2840 U/L. Surgical review: conservative management initially. Antibiotics withheld unless infection confirmed. ERCP considered if common bile duct calculi on MRCP.',
 9),

(11010, 15463, '2026-05-11 10:30:00',
 'AKI stage 3 secondary to contrast nephropathy (CTPA performed 3 days ago for PE workup). Urine output 0.2 ml/kg/hr despite 500ml fluid challenge. Creatinine 480 umol/L (baseline 85 umol/L, eGFR 72). CVVH commenced via right femoral Vascath (Prismax, CVVHDF mode, 35 ml/kg/hr). Fluid balance target: -800 ml over 24h. Haemodynamically stable: no vasopressors. Electrolytes: K+ 5.8 mmol/L (trending down on CVVH). Renally-adjusted medications. Nephrology review in progress. No active haemorrhage.',
 5),

(11011, 13091, '2026-05-11 06:00:00',
 'Heroin overdose. Found unresponsive at home by flatmate, brought in by ambulance. GCS 6 (E1V1M4) on arrival. Airway secured: RSI, intubated. Naloxone 0.4mg IV x2 - partial response (GCS improved to 8 then plateaued). ABG: pH 7.18, pCO2 8.2 kPa, pO2 14.5 (on 60% O2). Mechanically ventilated: controlled mode. Toxicology screen: opiates +++, benzodiazepines +. ECG: QTc 420ms. Paracetamol level within normal limits. Social work referral placed. Family notified. Drug liaison nurse to review.',
 2),

(11012, 17824, '2026-05-11 08:00:00',
 'Flame burns sustained in house fire. TBSA 42% (face 4.5%, anterior trunk 18%, bilateral upper limbs 19.5%); mixed partial and full thickness. Inhalation injury: carbonaceous sputum on intubation, vocal cord oedema on laryngoscopy. Parkland formula: 4 ml/kg/% TBSA = 12,400 ml Hartmann''s over 24h (50% in first 8h). Urine output target 0.5-1 ml/kg/hr. Escharotomy performed bilateral upper limbs. Analgesia: morphine PCA. Burns surgery review: skin grafting planned for day 3-5. Eyes: irrigation performed, ophthalmology review arranged. Tetanus prophylaxis given.',
 9),

(11013, 12516, '2026-05-11 12:00:00',
 'Post-operative day 1 following orthotopic liver transplantation for alcoholic cirrhosis (Child-Pugh C, MELD score 28, donor-recipient match excellent). Bile T-tube output 80 ml/hr (golden bile - primary graft function). LFTs improving: ALT 240 (was 890 POD0), bilirubin 85 (was 148). Immunosuppression: tacrolimus (FK506) target trough 10-15 ng/ml + mycophenolate mofetil 750mg BD. CMV prophylaxis: valganciclovir. PJP prophylaxis: co-trimoxazole. Extubated this morning, SpO2 97% on 4L/min. Epidural analgesia providing good pain control.',
 6),

(11014, 19347, '2026-05-11 07:15:00',
 'Severe diabetic ketoacidosis: venous pH 7.05, glucose 38.2 mmol/L, bicarbonate 4 mmol/L, ketones 6.8 mmol/L (blood), anion gap 32 mmol/L. Precipitant: deliberate insulin omission. Fixed-rate insulin infusion 0.1 units/kg/hr (6 units/hr). IV fluid replacement: 1L 0.9% NaCl over 1hr then 500ml/hr Hartmann''s. Potassium: K+ 2.8 mmol/L - replacement 40 mmol KCl in 500ml Hartmann''s running. Hourly capillary blood glucose and hourly venous blood gas. Endocrinology referral placed. Psychiatric review requested (deliberate omission).',
 6),

(11015, 14102, '2026-05-11 10:00:00',
 'Severe CAP (CURB-65 score 4). Admitted from ED with type 2 respiratory failure: PaO2 7.2 kPa on 60% Venturi mask, pCO2 7.8 kPa. Intubated on ICU: FiO2 0.55, PEEP 8, Vt 450 ml, RR 18. CXR: bilateral lobar consolidation (right > left). Sputum culture: Streptococcus pneumoniae (pending sensitivities). Antibiotics: amoxicillin-clavulanate 1.2g TDS + clarithromycin 500mg BD IV. Physiotherapy: airway clearance BD. Glucose management ongoing (stress hyperglycaemia). Renal function and electrolytes normal. No active bleeding.',
 5),

(11016, 16758, '2026-05-11 08:45:00',
 'Massive upper GI haemorrhage. Emergency OGD: Forrest Ia bleeding peptic ulcer (posterior wall duodenum, 2cm diameter). Dual endoscopic therapy: 1:10,000 adrenaline injection + haemoclip application - haemostasis achieved. Pre-endoscopy: Hb 61 g/L, BP 88/54. Resuscitation: 2 units pRBC transfused intra-procedure (Hb now 82 g/L). High-dose IV PPI: omeprazole 80mg bolus then 8mg/hr infusion. NBM. Repeat OGD planned at 24 hours. Surgical and interventional radiology team on standby. H. pylori CLO test taken during endoscopy.',
 7),

(11017, 11893, '2026-05-11 09:30:00',
 'Massive PE confirmed on CTPA: bilateral saddle embolism with right heart strain (RV:LV ratio 1.6 on CT, RV dilation and hypokinesis on echo, TR velocity 4.1 m/s). Haemodynamically unstable on arrival: BP 82/50, HR 128, SpO2 88% on 15L non-rebreathe. Decision for systemic thrombolysis: alteplase 100mg over 2 hours administered. Post-thrombolysis (current): BP 95/62, HR 112, SpO2 96% on 6L/min. Anticoagulation: unfractionated heparin infusion commenced 2h post-thrombolysis. Repeat echo at 6h. Monitor closely for haemorrhagic complications.',
 8),

(11018, 15024, '2026-05-11 07:00:00',
 'Bacterial meningitis confirmed: CSF turbid, protein 4.2 g/L, glucose 0.8 mmol/L (blood glucose 5.4, ratio 0.15), WBC 2200 cells/microL (90% PMN), Gram-negative diplococci on Gram stain. CSF PCR: Neisseria meningitidis serogroup B. High-dose IV ceftriaxone 2g BD commenced. Dexamethasone 0.15 mg/kg q6h x4 days. Seizure prophylaxis: levetiracetam 1000mg BD. Petechial rash spreading on lower limbs - monitoring for purpura fulminans. Haemodynamically compromised: norepinephrine 0.08 mcg/kg/min. Public health notification submitted.',
 9),

(11019, 18436, '2026-05-11 11:30:00',
 'Post right lower lobectomy for stage IIA non-small-cell lung cancer (adenocarcinoma, T2bN0M0). Video-assisted thoracoscopic surgery (VATS) approach. Epidural analgesia (bupivacaine 0.1% + fentanyl 2 mcg/ml at 8 ml/hr) providing excellent pain control (NRS 3/10 on movement). Chest drains x2: air leak resolved at 2h post-op, current output 45 ml/hr serosanguineous. SpO2 97% on 4L/min O2 via nasal cannula. CXR: right lower zone atelectasis - physiotherapy twice daily. Deep breathing exercises. Early mobilisation: sat out of bed at 6h post-op. Surgical oncology follow-up in 4 weeks.',
 7),

(11020, 13615, '2026-05-11 06:30:00',
 'Hypertensive emergency: BP 230/140 mmHg on arrival with confusion, severe occipital headache, visual disturbance (blurred vision, photopsia) and vomiting. CT head: no haemorrhage, bilateral posterior white matter T2 signal change (PRES pattern). Fundoscopy: papilloedema grade 3, flame-shaped haemorrhages. IV labetalol infusion commenced (current rate 4 mg/min): BP now 185/110 and decreasing. Target: reduce MAP by 20-25% over first hour, then gradually to 160/100 over 24h. Creatinine 145 umol/L (possible hypertensive nephrosclerosis). Ophthalmic review. Secondary causes workup: renal artery Doppler, aldosterone:renin ratio, catecholamines.',
 6);
