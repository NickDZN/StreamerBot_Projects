--- Calc_hcc_costs.pl\AND sbfm.budget_code = bcma.budget_code ---
                AND sbfm.budget_code = bcma.budget_code
                AND sbfm.engineering_classification = bcma.engineering_classification
                AND bcma.dno = v2_dno
                AND sbfm.budget_code_date_from = bc.date_from            
                AND sbfm.budget_code_date_from = bcma.budget_code_date_from                
                AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
                AND sv.scheme_id = sbfm.scheme_id
                AND sv.scheme_version = sbfm.scheme_version



                AND sbfm.engineering_classification = bcma.engineering_classification
                AND sbfm.budget_code_date_from = bc.date_from
                AND sbfm.budget_code = bcma.budget_code
                AND sbfm.budget_code_date_from = bcma.budget_code_date_from
                AND bcma.dno = v2_dno
                AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
                AND sv.scheme_id = sbfm.scheme_id
                AND sv.scheme_version = sbfm.scheme_version
                AND bcma.date_to IS NULL

--- Calc_hcc_costs.pl\calc_hcc_costs_new.pl ---
CREATE OR REPLACE PROCEDURE calc_hcc_costs (
                              pn_scheme_id      IN NUMBER,
                              pn_scheme_version IN NUMBER,
                              pn_type_of_expen  IN NUMBER,
                              p2_bud_code_1     IN VARCHAR2,
                              p2_bud_code_2     IN VARCHAR2, 
                              p2_lvl_1          IN VARCHAR2, 
                              p2_lvl_2          IN VARCHAR2, 
                              p2_expen_type     IN NUMBER, 
                              pn_total_cost     OUT NUMBER 
                            ) IS

  v2_work_category_level  VARCHAR2(2500);
  vn_cost_1               NUMBER;
  vn_cost_2               NUMBER;
  vn_scheme_id            NUMBER;
  vn_scheme_version       NUMBER;
  vn_type_of_expen        NUMBER;
  v2_bud_code_1           VARCHAR2(10);
  v2_bud_code_2           VARCHAR2(10);
  vn_expen_type           NUMBER;
  v2_lvl_1                VARCHAR2(10);
  v2_lvl_2                VARCHAR2(10);
  v2_terms1	              VARCHAR2(100);
  v2_terms2	              VARCHAR2(100);
  v2_terms3	              VARCHAR2(100);
  v2_terms4	              VARCHAR2(100);
  v2_terms5	              VARCHAR2(100);
  v2_terms6	              VARCHAR2(100);
  v2_terms7	              VARCHAR2(100);
  v2_terms8	              VARCHAR2(100);
  v2_terms9	              VARCHAR2(100);
  v2_terms10	            VARCHAR2(100);
  v2_terms11	            VARCHAR2(100);
  v2_terms12	            VARCHAR2(100);
  v2_terms13	            VARCHAR2(100);
  v2_terms14	            VARCHAR2(100);
  v2_terms15	            VARCHAR2(100);
  v2_terms16	            VARCHAR2(100);
  v2_terms17	            VARCHAR2(100);
  v2_terms18	            VARCHAR2(100);
  v2_terms19	            VARCHAR2(100);
  v2_terms20	            VARCHAR2(100);

  CURSOR get_costs IS
    SELECT SUM(contestable_cost),
           SUM(noncontestable_cost)  
     FROM (SELECT DISTINCT 
                    1,
                    decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)) CONTESTABLE_COST,
                    decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)) NONCONTESTABLE_COST,
                    nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
                    nvl(swe.description_for_customer,ci.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
             FROM scheme_breakdown_for_margins sbfm,
                  cost_item ci,
                  cost_item_allocation$v cia,
                  cost_item_element cie,
                  cost_item_element	non_cont,
                  cost_item_element	cont,
                  work_category_for_scheme wcfs,
                  standard_work_element swe,
                  work_category wc,
                  work_category_association wca,
                  budget_code_for_scheme_split bcfss,
                  budget_code bc,
                 (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                    FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                   WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     AND rsi1.CONTINGENCY_IND = 'Y') ts
             WHERE sbfm.scheme_id = vn_scheme_id
               AND sbfm.scheme_version = vn_scheme_version
               AND sbfm.userid = user_pk.get_userid
               AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
               AND ts.scheme_id(+) = sbfm.scheme_id
               AND ts.scheme_version(+) = sbfm.scheme_version
               AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
               AND ci.cost_item_id = sbfm.cost_item_id
               AND ci.cost_item_indicator != 'T'
               AND cie.cost_item_id = ci.cost_item_id
               AND cie.budget_code IS NULL
               AND swe.standard_work_element_id(+) = ci.standard_work_element_id
               AND bcfss.scheme_id = sbfm.scheme_id
               AND bcfss.scheme_version = sbfm.scheme_version
               AND bc.budget_code = bcfss.budget_code
               AND bc.date_from = bcfss.budget_code_date_from
               AND bc.type_of_expenditure_ri = vn_expen_type
               AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
               AND wc.work_category = wcfs.work_category_1
               AND wca.work_category_1(+) = wcfs.work_category_1
               AND wca.work_category_2(+) = wcfs.work_category_2
               AND non_cont.cost_item_id(+) = sbfm.cost_item_id
               AND non_cont.type_of_cost_ri(+) = 206
               AND cont.cost_item_id(+) = sbfm.cost_item_id
               AND cont.type_of_cost_ri(+) = 207
               AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
               AND cia.cost_item_id = ci.cost_item_id
               AND cia.type_of_expenditure_ri = vn_expen_type
               AND cia.budget_code IN (v2_bud_code_1,v2_bud_code_2)
             UNION
            SELECT DISTINCT 
                      1,
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)) CONTESTABLE_COST,
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)) NONCONTESTABLE_COST,
                      nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                      NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                      nvl(swe.description_for_customer,ci.description) swe_description,
                      sbfm.description,
                      sbfm.cost_item_id
              FROM scheme_breakdown_for_margins sbfm,
                   cost_item ci,
                   work_category_for_scheme wcfs,
                   cost_item_element non_cont,
                   cost_item_element cont,
                   standard_work_element swe,
                   work_category_association wca,
                   work_category wc,
                   cost_item_allocation$v cia,
                  (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                     from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                    where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                      and rsi1.CONTINGENCY_IND = 'Y') ts
             WHERE sbfm.scheme_id = vn_scheme_id
               AND sbfm.scheme_version = vn_scheme_version
               AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
               AND sbfm.userid = user_pk.get_userid
               AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
               AND ts.scheme_id(+) = sbfm.scheme_id
               AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
               AND ci.cost_item_id = sbfm.cost_item_id
               AND ci.cost_item_indicator != 'T'
               AND cia.cost_item_id = ci.cost_item_id
               AND cia.type_of_expenditure_ri = vn_expen_type
               AND cia.split_indicator = 0
               AND swe.standard_work_element_id(+) = ci.standard_work_element_id
               AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
               AND wc.work_category = wcfs.work_category_1
               AND wca.work_category_1(+) = wcfs.work_category_1
               AND wca.work_category_2(+) = wcfs.work_category_2
               AND non_cont.cost_item_id(+) = ci.cost_item_id
               AND non_cont.type_of_cost_ri(+) = 206
               AND cont.cost_item_id(+) = ci.cost_item_id
               AND cont.type_of_cost_ri(+) = 207
               AND cia.BUDGET_CODE IN (v2_bud_code_1,v2_bud_code_2)
             UNION
            SELECT DISTINCT 
                      1,
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)) CONTESTABLE_COST,
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)) NONCONTESTABLE_COST,
                      nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                      NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                      nvl(swe.description_for_customer,cip.description) swe_description,
                      sbfm.description,
                      sbfm.cost_item_id
              FROM  scheme_breakdown_for_margins sbfm,
                    cost_item ci,
                    work_category_for_scheme wcfs,
                    cost_item_element non_cont,
                    cost_item_element cont,
                    standard_work_element swe,
                    work_category_association wca,
                    work_category wc,
                    cost_item_allocation$v cia,
                    cost_item cip,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                      FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                     WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE sbfm.scheme_id = vn_scheme_id
                AND sbfm.scheme_version = vn_scheme_version
                AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
                AND sbfm.userid = user_pk.get_userid
                AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                AND cip.cost_item_id = sbfm.cost_item_id
                AND cip.cost_item_indicator != 'T'
                AND ci.parent_cost_item_id = cip.cost_item_id
                AND cia.cost_item_id = ci.cost_item_id
                AND cia.type_of_expenditure_ri = vn_expen_type
                AND cia.split_indicator = 0
                AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
                AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND wc.work_category = wcfs.work_category_1
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND non_cont.cost_item_id(+) = sbfm.cost_item_id
                AND non_cont.type_of_cost_ri(+) = 206
                AND cont.cost_item_id(+) = sbfm.cost_item_id
                AND cont.type_of_cost_ri(+) = 207
                AND cia.BUDGET_CODE IN (v2_bud_code_1,v2_bud_code_2)
              UNION   
             SELECT 2,
                    sum(CONTESTABLE_COST), 
                    sum(NONCONTESTABLE_COST), 
                    work_cat_desc,total_quantity, 
                    'Travel', 
                    budget_code,work_cat_for_scheme_id 
               FROM (SELECT DISTINCT 
                              2,
                              decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                              decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code,
                              wcfs.work_cat_for_scheme_id
                       FROM travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            budget_code bc,
                            work_category wc,
                            cost_item ci,
                          (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                             FROM terms_split ts1, recharge_statement_info rsi1
                            WHERE ts1.terms_split_id = rsi1.terms_split_id
                              AND rsi1.CONTINGENCY_IND = 'Y') ts
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        AND wca.work_category_1(+) = wcfs.work_category_1
                        AND wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        AND ci.scheme_id = sbfm.scheme_id
                        AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                        AND ci.COST_ITEM_INDICATOR = 'T'
                        AND ts.scheme_id(+) = sbfm.scheme_id
                        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                        AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                        AND bc.type_of_expenditure_ri = vn_expen_type
                        AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND sbfm.scheme_version = wcfs.scheme_version
                        AND sbfm.scheme_id = vn_scheme_id
                        AND sbfm.scheme_version = vn_scheme_version
                        AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
                        AND sbfm.userid = user_pk.get_userid
                      UNION
                     SELECT DISTINCT 
                              2,
                              round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N', round(sbfm.cont_travel_cost,2), round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*(bcma.margin)/100,2) CONTESTABLE_COST2,
                              0 NONCONTESTABLE_COST,
                              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code,
                              wcfs.work_cat_for_scheme_id
                       FROM travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            budget_code bc,
                            work_category wc,
                            cost_item ci,
                            scheme_version sv,
                            budget_code_margin_applicable bcma,
                           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                             WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                               AND rsi1.CONTINGENCY_IND = 'Y') ts
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        AND wca.work_category_1(+) = wcfs.work_category_1
                        AND wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        AND ci.scheme_id = sbfm.scheme_id
                        AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                        AND ci.COST_ITEM_INDICATOR = 'T'
                        AND ts.scheme_id(+) = sbfm.scheme_id
                        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                        AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                        AND sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
                        AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
                        AND sbfm.budget_code = bcma.BUDGET_CODE
                        AND sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
                        AND sv.scheme_id = sbfm.scheme_id
                        AND sv.scheme_version = sbfm.scheme_version
                        AND bcma.date_to is null
                        AND bc.type_of_expenditure_ri = vn_expen_type
                        AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND sbfm.scheme_version = wcfs.scheme_version
                        AND sbfm.scheme_id = vn_scheme_id
                        AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
                        AND sbfm.scheme_version =vn_scheme_version
                        AND sbfm.userid = user_pk.get_userid)
                      GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id);

BEGIN
  vn_scheme_id      := pn_scheme_id;
  vn_scheme_version := pn_scheme_version;
  vn_type_of_expen  := pn_type_of_expen;
  v2_bud_code_1     := p2_bud_code_1;
  v2_bud_code_2     := p2_bud_code_2;
  v2_lvl_1          := p2_lvl_1;
  v2_lvl_2          := p2_lvl_2;
  vn_expen_type     := p2_expen_type;

  IF v2_lvl_1 = 'LV' AND v2_lvl_2 = 'LV' THEN
    v2_terms1 := 'CABLE JOINTING - LV';
    v2_terms2 := 'CABLE LAYING - LV';
    v2_terms3 := 'CABLE TRENCHING - LV';
    v2_terms4 := 'OVERHEAD MAINS ADDITIONS - LV';
    v2_terms5 := 'OVERHEAD MAINS REPLACEMENT - LV';
    v2_terms6 := 'SERVICES-OVERHEAD';
    v2_terms7 := 'SERVICES-PUBLIC LIGHTING';
    v2_terms8 := 'SERVICES-TRENCHING';
    v2_terms9 := 'SERVICES-UNDERGROUND';
    v2_terms10 := NULL;
    v2_terms11 := NULL;
    v2_terms12 := NULL;
    v2_terms13 := NULL;
    v2_terms14 := NULL;
    v2_terms15 := NULL;
    v2_terms16 := NULL;
    v2_terms17 := NULL;
    v2_terms18 := NULL;
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'LV' AND v2_lvl_2 = 'HV' THEN
    v2_terms1 := 'CABLE JOINTING - LV';
    v2_terms2 := 'CABLE LAYING - LV';
    v2_terms3 := 'CABLE TRENCHING - LV';
    v2_terms4 := 'OVERHEAD MAINS ADDITIONS - LV';
    v2_terms5 := 'OVERHEAD MAINS REPLACEMENT - LV';
    v2_terms6 := 'SERVICES-OVERHEAD';
    v2_terms7 := 'SERVICES-PUBLIC LIGHTING';
    v2_terms8 := 'SERVICES-TRENCHING';
    v2_terms9 := 'SERVICES-UNDERGROUND';
    v2_terms10 := 'CABLE JOINTING - 11kV';
    v2_terms11 := 'CABLE LAYING - 11kV';
    v2_terms12 := 'CABLE TRENCHING - 11kV';
    v2_terms13 := 'CIVIL WORKS - 11kV';
    v2_terms14 := 'LAND - 11kV';
    v2_terms15 := 'OVERHEAD MAINS ADDITIONS - 11kV';
    v2_terms16 := 'OVERHEAD MAINS REPLACEMENT - 11kV';
    v2_terms17 := 'PLANT + MACHINERY (GM) - 11kV';
    v2_terms18 := 'PLANT + MACHINERY (PM) - 11kV';
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  ELSIF v2_lvl_1  ='LV' AND v2_lvl_2 = 'EHV' THEN
    v2_terms1 := 'CABLE JOINTING - LV';
    v2_terms2 := 'CABLE LAYING - LV';
    v2_terms3 := 'CABLE TRENCHING - LV';
    v2_terms4 := 'OVERHEAD MAINS ADDITIONS - LV';
    v2_terms5 := 'OVERHEAD MAINS REPLACEMENT - LV';
    v2_terms6 := 'SERVICES-OVERHEAD';
    v2_terms7 := 'SERVICES-PUBLIC LIGHTING';
    v2_terms8 := 'SERVICES-TRENCHING';
    v2_terms9 := 'SERVICES-UNDERGROUND';
    v2_terms10 := 'CABLE JOINTING - 33kV';
    v2_terms11 := 'CABLE LAYING - 33kV';
    v2_terms12 := 'CABLE TRENCHING - 33kV';
    v2_terms13 := 'CIVIL WORKS - 33kV';
    v2_terms14 := 'LAND - 33kV';
    v2_terms15 := 'OVERHEAD MAINS ADDITIONS - 33kV';
    v2_terms16 := 'OVERHEAD MAINS REPLACEMENT - 33kV';
    v2_terms17 := 'PLANT + MACHINERY - 33kV';
    v2_terms18 := 'TOWER CONSTRUCTION  - 66kV';
    v2_terms19 := 'TOWER CONSTRUCTION  - 33kV';
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'HV' AND v2_lvl_2 = 'HV' THEN
    v2_terms1 := 'CABLE JOINTING - 11kV';
    v2_terms2 := 'CABLE LAYING - 11kV';
    v2_terms3 := 'CABLE TRENCHING - 11kV';
    v2_terms4 := 'CIVIL WORKS - 11kV';
    v2_terms5 := 'LAND - 11kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 11kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 11kV';
    v2_terms8 := 'PLANT + MACHINERY (GM) - 11kV';
    v2_terms9 := 'PLANT + MACHINERY (PM) - 11kV';
    v2_terms10 := 'PRIMARY SWITCHGEAR - 11kV';
    v2_terms11 := NULL;
    v2_terms12 := NULL;
    v2_terms13 := NULL;
    v2_terms14 := NULL;
    v2_terms15 := NULL;
    v2_terms16 := NULL;
    v2_terms17 := NULL;
    v2_terms18 := NULL;
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'HV' AND v2_lvl_2 = 'EHV' THEN
    v2_terms1 := 'CABLE JOINTING - 11kV';
    v2_terms2 := 'CABLE LAYING - 11kV';
    v2_terms3 := 'CABLE TRENCHING - 11kV';
    v2_terms4 := 'CIVIL WORKS - 11kV';
    v2_terms5 := 'LAND - 11kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 11kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 11kV';
    v2_terms8 := 'PLANT + MACHINERY (GM) - 11kV';
    v2_terms9 := 'PLANT + MACHINERY (PM) - 11kV';
    v2_terms10 := 'PRIMARY SWITCHGEAR - 11kV';
    v2_terms11 := 'CABLE JOINTING - 33kV';
    v2_terms12 := 'CABLE LAYING - 33kV';
    v2_terms13 := 'CABLE TRENCHING - 33kV';
    v2_terms14 := 'CIVIL WORKS - 33kV';
    v2_terms15 := 'LAND - 33kV';
    v2_terms16 := 'OVERHEAD MAINS ADDITIONS - 33kV';
    v2_terms17 := 'OVERHEAD MAINS REPLACEMENT - 33kV';
    v2_terms18 := 'PLANT + MACHINERY - 33kV';
    v2_terms19 := 'TOWER CONSTRUCTION  - 66kV';
    v2_terms20 := 'TOWER CONSTRUCTION  - 33kV';

  ELSIF v2_lvl_1 = 'HV' AND v2_lvl_2 = '132' THEN
    v2_terms1 := 'CABLE JOINTING - 11kV';
    v2_terms2 := 'CABLE LAYING - 11kV';
    v2_terms3 := 'CABLE TRENCHING - 11kV';
    v2_terms4 := 'CIVIL WORKS - 11kV';
    v2_terms5 := 'LAND - 11kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 11kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 11kV';
    v2_terms8 := 'PLANT + MACHINERY (GM) - 11kV';
    v2_terms9 := 'PLANT + MACHINERY (PM) - 11kV';
    v2_terms10 := 'PRIMARY SWITCHGEAR - 11kV';
    v2_terms11 := 'CABLE JOINTING - 132kV';
    v2_terms12 := 'CABLE LAYING - 132kV';
    v2_terms13 := 'CABLE TRENCHING - 132kV';
    v2_terms14 := 'CIVIL WORKS - 132kV';
    v2_terms15 := 'LAND - 132kV';
    v2_terms16 := 'OVERHEAD MAINS ADDITIONS - 132kV';
    v2_terms17 := 'OVERHEAD MAINS REPLACEMENT - 132kV';
    v2_terms18 := 'PLANT + MACHINERY - 132kV';
    v2_terms19 := 'TOWER CONSTRUCTION  - 132kV';
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'EHV' AND v2_lvl_2 = 'EHV' THEN
    v2_terms1 := 'CABLE JOINTING - 33kV';
    v2_terms2 := 'CABLE LAYING - 33kV';
    v2_terms3 := 'CABLE TRENCHING - 33kV';
    v2_terms4 := 'CIVIL WORKS - 33kV';
    v2_terms5 := 'LAND - 33kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 33kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 33kV';
    v2_terms8 := 'PLANT + MACHINERY - 33kV';
    v2_terms9 := 'TOWER CONSTRUCTION  - 66kV';
    v2_terms10 := 'TOWER CONSTRUCTION  - 33kV';
    v2_terms11 := NULL;
    v2_terms12 := NULL;
    v2_terms13 := NULL;
    v2_terms14 := NULL;
    v2_terms15 := NULL;
    v2_terms16 := NULL;
    v2_terms17 := NULL;
    v2_terms18 := NULL;
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'EHV' AND v2_lvl_2 = '132' THEN
    v2_terms1 := 'CABLE JOINTING - 33kV';
    v2_terms2 := 'CABLE LAYING - 33kV';
    v2_terms3 := 'CABLE TRENCHING - 33kV';
    v2_terms4 := 'CIVIL WORKS - 33kV';
    v2_terms5 := 'LAND - 33kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 33kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 33kV';
    v2_terms8 := 'PLANT + MACHINERY - 33kV';
    v2_terms9 := 'TOWER CONSTRUCTION  - 66kV';
    v2_terms10 := 'TOWER CONSTRUCTION  - 33kV';
    v2_terms11 := 'CABLE JOINTING - 132kV';
    v2_terms12 := 'CABLE LAYING - 132kV';
    v2_terms13 := 'CABLE TRENCHING - 132kV';
    v2_terms14 := 'CIVIL WORKS - 132kV';
    v2_terms15 := 'LAND - 132kV';
    v2_terms16 := 'OVERHEAD MAINS ADDITIONS - 132kV';
    v2_terms17 := 'OVERHEAD MAINS REPLACEMENT - 132kV';
    v2_terms18 := 'PLANT + MACHINERY - 132kV';
    v2_terms19 := 'TOWER CONSTRUCTION  - 132kV';
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = '132' AND v2_lvl_2 = '132' THEN
    v2_terms1 := 'CABLE JOINTING - 132kV';
    v2_terms2 := 'CABLE LAYING - 132kV';
    v2_terms3 := 'CABLE TRENCHING - 132kV';
    v2_terms4 := 'CIVIL WORKS - 132kV';
    v2_terms5 := 'LAND - 132kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 132kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 132kV';
    v2_terms8 := 'PLANT + MACHINERY - 132kV';
    v2_terms9 := 'TOWER CONSTRUCTION  - 132kV';
    v2_terms10 := NULL;
    v2_terms11 := NULL;
    v2_terms12 := NULL;
    v2_terms13 := NULL;
    v2_terms14 := NULL;
    v2_terms15 := NULL;
    v2_terms16 := NULL;
    v2_terms17 := NULL;
    v2_terms18 := NULL;
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  END IF;

  OPEN get_costs;
  FETCH get_costs
  INTO vn_cost_1, vn_cost_2;
  CLOSE get_costs;

  pn_total_cost := vn_cost_1 + vn_cost_2;

EXCEPTION
  WHEN others THEN
    dbms_output.put_line('Error in getting cost'||SQLERRM);
END calc_hcc_costs;

--- Calc_hcc_costs.pl\calc_hcc_costs_old.sql ---
CREATE OR REPLACE PROCEDURE calc_hcc_costs (
                              pn_scheme_id      IN NUMBER,
                              pn_scheme_version IN NUMBER,
                              pn_type_of_expen  IN NUMBER,
                              p2_bud_code_1     IN VARCHAR2,
                              p2_bud_code_2     IN VARCHAR2, 
                              p2_lvl_1          IN VARCHAR2, 
                              p2_lvl_2          IN VARCHAR2, 
                              p2_expen_type     IN NUMBER, 
                              pn_total_cost     OUT NUMBER 
                            ) IS

  v2_work_category_level  VARCHAR2(2500);
  vn_cost_1               NUMBER;
  vn_cost_2               NUMBER;
  vn_scheme_id            NUMBER;
  vn_scheme_version       NUMBER;
  vn_type_of_expen        NUMBER;
  v2_bud_code_1           VARCHAR2(10);
  v2_bud_code_2           VARCHAR2(10);
  vn_expen_type           NUMBER;
  v2_lvl_1                VARCHAR2(10);
  v2_lvl_2                VARCHAR2(10);
  v2_terms1	              VARCHAR2(100);
  v2_terms2	              VARCHAR2(100);
  v2_terms3	              VARCHAR2(100);
  v2_terms4	              VARCHAR2(100);
  v2_terms5	              VARCHAR2(100);
  v2_terms6	              VARCHAR2(100);
  v2_terms7	              VARCHAR2(100);
  v2_terms8	              VARCHAR2(100);
  v2_terms9	              VARCHAR2(100);
  v2_terms10	            VARCHAR2(100);
  v2_terms11	            VARCHAR2(100);
  v2_terms12	            VARCHAR2(100);
  v2_terms13	            VARCHAR2(100);
  v2_terms14	            VARCHAR2(100);
  v2_terms15	            VARCHAR2(100);
  v2_terms16	            VARCHAR2(100);
  v2_terms17	            VARCHAR2(100);
  v2_terms18	            VARCHAR2(100);
  v2_terms19	            VARCHAR2(100);
  v2_terms20	            VARCHAR2(100);

  CURSOR get_costs IS
    SELECT SUM(contestable_cost),
           SUM(noncontestable_cost)  
     FROM (SELECT DISTINCT 
                    1,
                    decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)) CONTESTABLE_COST,
                    decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)) NONCONTESTABLE_COST,
                    nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
                    nvl(swe.description_for_customer,ci.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
             FROM scheme_breakdown_for_margins sbfm,
                  cost_item ci,
                  cost_item_allocation$v cia,
                  cost_item_element cie,
                  cost_item_element	non_cont,
                  cost_item_element	cont,
                  work_category_for_scheme wcfs,
                  standard_work_element swe,
                  work_category wc,
                  work_category_association wca,
                  budget_code_for_scheme_split bcfss,
                  budget_code bc,
                 (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                    FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                   WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     AND rsi1.CONTINGENCY_IND = 'Y') ts
             WHERE sbfm.scheme_id = vn_scheme_id
               AND sbfm.scheme_version = vn_scheme_version
               AND sbfm.userid = user_pk.get_userid
               AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
               AND ts.scheme_id(+) = sbfm.scheme_id
               AND ts.scheme_version(+) = sbfm.scheme_version
               AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
               AND ci.cost_item_id = sbfm.cost_item_id
               AND ci.cost_item_indicator != 'T'
               AND cie.cost_item_id = ci.cost_item_id
               AND cie.budget_code IS NULL
               AND swe.standard_work_element_id(+) = ci.standard_work_element_id
               AND bcfss.scheme_id = sbfm.scheme_id
               AND bcfss.scheme_version = sbfm.scheme_version
               AND bc.budget_code = bcfss.budget_code
               AND bc.date_from = bcfss.budget_code_date_from
               AND bc.type_of_expenditure_ri = vn_expen_type
               AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
               AND wc.work_category = wcfs.work_category_1
               AND wca.work_category_1(+) = wcfs.work_category_1
               AND wca.work_category_2(+) = wcfs.work_category_2
               AND non_cont.cost_item_id(+) = sbfm.cost_item_id
               AND non_cont.type_of_cost_ri(+) = 206
               AND cont.cost_item_id(+) = sbfm.cost_item_id
               AND cont.type_of_cost_ri(+) = 207
               AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
               AND cia.cost_item_id = ci.cost_item_id
               AND cia.type_of_expenditure_ri = vn_expen_type
               AND cia.budget_code IN (v2_bud_code_1,v2_bud_code_2)
             UNION
            SELECT DISTINCT 
                      1,
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)) CONTESTABLE_COST,
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)) NONCONTESTABLE_COST,
                      nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                      NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                      nvl(swe.description_for_customer,ci.description) swe_description,
                      sbfm.description,
                      sbfm.cost_item_id
              FROM scheme_breakdown_for_margins sbfm,
                   cost_item ci,
                   work_category_for_scheme wcfs,
                   cost_item_element non_cont,
                   cost_item_element cont,
                   standard_work_element swe,
                   work_category_association wca,
                   work_category wc,
                   cost_item_allocation$v cia,
                  (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                     from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                    where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                      and rsi1.CONTINGENCY_IND = 'Y') ts
             WHERE sbfm.scheme_id = vn_scheme_id
               AND sbfm.scheme_version = vn_scheme_version
               AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
               AND sbfm.userid = user_pk.get_userid
               AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
               AND ts.scheme_id(+) = sbfm.scheme_id
               AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
               AND ci.cost_item_id = sbfm.cost_item_id
               AND ci.cost_item_indicator != 'T'
               AND cia.cost_item_id = ci.cost_item_id
               AND cia.type_of_expenditure_ri = vn_expen_type
               AND cia.split_indicator = 0
               AND swe.standard_work_element_id(+) = ci.standard_work_element_id
               AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
               AND wc.work_category = wcfs.work_category_1
               AND wca.work_category_1(+) = wcfs.work_category_1
               AND wca.work_category_2(+) = wcfs.work_category_2
               AND non_cont.cost_item_id(+) = ci.cost_item_id
               AND non_cont.type_of_cost_ri(+) = 206
               AND cont.cost_item_id(+) = ci.cost_item_id
               AND cont.type_of_cost_ri(+) = 207
               AND cia.BUDGET_CODE IN (v2_bud_code_1,v2_bud_code_2)
             UNION
            SELECT DISTINCT 
                      1,
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)) CONTESTABLE_COST,
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)) NONCONTESTABLE_COST,
                      nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                      NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                      nvl(swe.description_for_customer,cip.description) swe_description,
                      sbfm.description,
                      sbfm.cost_item_id
              FROM  scheme_breakdown_for_margins sbfm,
                    cost_item ci,
                    work_category_for_scheme wcfs,
                    cost_item_element non_cont,
                    cost_item_element cont,
                    standard_work_element swe,
                    work_category_association wca,
                    work_category wc,
                    cost_item_allocation$v cia,
                    cost_item cip,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                      FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                     WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE sbfm.scheme_id = vn_scheme_id
                AND sbfm.scheme_version = vn_scheme_version
                AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
                AND sbfm.userid = user_pk.get_userid
                AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                AND cip.cost_item_id = sbfm.cost_item_id
                AND cip.cost_item_indicator != 'T'
                AND ci.parent_cost_item_id = cip.cost_item_id
                AND cia.cost_item_id = ci.cost_item_id
                AND cia.type_of_expenditure_ri = vn_expen_type
                AND cia.split_indicator = 0
                AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
                AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND wc.work_category = wcfs.work_category_1
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND non_cont.cost_item_id(+) = sbfm.cost_item_id
                AND non_cont.type_of_cost_ri(+) = 206
                AND cont.cost_item_id(+) = sbfm.cost_item_id
                AND cont.type_of_cost_ri(+) = 207
                AND cia.BUDGET_CODE IN (v2_bud_code_1,v2_bud_code_2)
              UNION   
             SELECT 2,
                    sum(CONTESTABLE_COST), 
                    sum(NONCONTESTABLE_COST), 
                    work_cat_desc,total_quantity, 
                    'Travel', 
                    budget_code,work_cat_for_scheme_id 
               FROM (SELECT DISTINCT 
                              2,
                              decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                              decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code,
                              wcfs.work_cat_for_scheme_id
                       FROM travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            budget_code bc,
                            work_category wc,
                            cost_item ci,
                          (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                             FROM terms_split ts1, recharge_statement_info rsi1
                            WHERE ts1.terms_split_id = rsi1.terms_split_id
                              AND rsi1.CONTINGENCY_IND = 'Y') ts
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        AND wca.work_category_1(+) = wcfs.work_category_1
                        AND wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        AND ci.scheme_id = sbfm.scheme_id
                        AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                        AND ci.COST_ITEM_INDICATOR = 'T'
                        AND ts.scheme_id(+) = sbfm.scheme_id
                        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                        AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                        AND bc.type_of_expenditure_ri = vn_expen_type
                        AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND sbfm.scheme_version = wcfs.scheme_version
                        AND sbfm.scheme_id = vn_scheme_id
                        AND sbfm.scheme_version = vn_scheme_version
                        AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
                        AND sbfm.userid = user_pk.get_userid
                      UNION
                     SELECT DISTINCT 
                              2,
                              round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N', round(sbfm.cont_travel_cost,2), round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*(bcma.margin)/100,2) CONTESTABLE_COST2,
                              0 NONCONTESTABLE_COST,
                              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code,
                              wcfs.work_cat_for_scheme_id
                       FROM travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            budget_code bc,
                            work_category wc,
                            cost_item ci,
                            scheme_version sv,
                            budget_code_margin_applicable bcma,
                           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                             WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                               AND rsi1.CONTINGENCY_IND = 'Y') ts
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        AND wca.work_category_1(+) = wcfs.work_category_1
                        AND wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        AND ci.scheme_id = sbfm.scheme_id
                        AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                        AND ci.COST_ITEM_INDICATOR = 'T'
                        AND ts.scheme_id(+) = sbfm.scheme_id
                        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                        AND sbfm.budget_code = bcma.budget_code
                        AND sbfm.engineering_classification = bcma.engineering_classification
                        AND bcma.dno = v2_dno
                        AND sbfm.budget_code_date_from = bc.date_from            
                        AND sbfm.budget_code_date_from = bcma.budget_code_date_from                
                        AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
                        AND sv.scheme_id = sbfm.scheme_id
                        AND sv.scheme_version = sbfm.scheme_version
                        AND bc.type_of_expenditure_ri = vn_expen_type
                        AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND sbfm.scheme_version = wcfs.scheme_version
                        AND sbfm.scheme_id = vn_scheme_id
                        AND wca.terms_work_category in (v2_terms1,v2_terms2,v2_terms3,v2_terms4,v2_terms5,v2_terms6,v2_terms7,v2_terms8,v2_terms9,v2_terms10,v2_terms11,v2_terms12,v2_terms13,v2_terms14,v2_terms15,v2_terms16,v2_terms17,v2_terms18,v2_terms19,v2_terms20)
                        AND sbfm.scheme_version =vn_scheme_version
                        AND sbfm.userid = user_pk.get_userid)
                      GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id);

BEGIN
  vn_scheme_id      := pn_scheme_id;
  vn_scheme_version := pn_scheme_version;
  vn_type_of_expen  := pn_type_of_expen;
  v2_bud_code_1     := p2_bud_code_1;
  v2_bud_code_2     := p2_bud_code_2;
  v2_lvl_1          := p2_lvl_1;
  v2_lvl_2          := p2_lvl_2;
  vn_expen_type     := p2_expen_type;

  IF v2_lvl_1 = 'LV' AND v2_lvl_2 = 'LV' THEN
    v2_terms1 := 'CABLE JOINTING - LV';
    v2_terms2 := 'CABLE LAYING - LV';
    v2_terms3 := 'CABLE TRENCHING - LV';
    v2_terms4 := 'OVERHEAD MAINS ADDITIONS - LV';
    v2_terms5 := 'OVERHEAD MAINS REPLACEMENT - LV';
    v2_terms6 := 'SERVICES-OVERHEAD';
    v2_terms7 := 'SERVICES-PUBLIC LIGHTING';
    v2_terms8 := 'SERVICES-TRENCHING';
    v2_terms9 := 'SERVICES-UNDERGROUND';
    v2_terms10 := NULL;
    v2_terms11 := NULL;
    v2_terms12 := NULL;
    v2_terms13 := NULL;
    v2_terms14 := NULL;
    v2_terms15 := NULL;
    v2_terms16 := NULL;
    v2_terms17 := NULL;
    v2_terms18 := NULL;
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'LV' AND v2_lvl_2 = 'HV' THEN
    v2_terms1 := 'CABLE JOINTING - LV';
    v2_terms2 := 'CABLE LAYING - LV';
    v2_terms3 := 'CABLE TRENCHING - LV';
    v2_terms4 := 'OVERHEAD MAINS ADDITIONS - LV';
    v2_terms5 := 'OVERHEAD MAINS REPLACEMENT - LV';
    v2_terms6 := 'SERVICES-OVERHEAD';
    v2_terms7 := 'SERVICES-PUBLIC LIGHTING';
    v2_terms8 := 'SERVICES-TRENCHING';
    v2_terms9 := 'SERVICES-UNDERGROUND';
    v2_terms10 := 'CABLE JOINTING - 11kV';
    v2_terms11 := 'CABLE LAYING - 11kV';
    v2_terms12 := 'CABLE TRENCHING - 11kV';
    v2_terms13 := 'CIVIL WORKS - 11kV';
    v2_terms14 := 'LAND - 11kV';
    v2_terms15 := 'OVERHEAD MAINS ADDITIONS - 11kV';
    v2_terms16 := 'OVERHEAD MAINS REPLACEMENT - 11kV';
    v2_terms17 := 'PLANT + MACHINERY (GM) - 11kV';
    v2_terms18 := 'PLANT + MACHINERY (PM) - 11kV';
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  ELSIF v2_lvl_1  ='LV' AND v2_lvl_2 = 'EHV' THEN
    v2_terms1 := 'CABLE JOINTING - LV';
    v2_terms2 := 'CABLE LAYING - LV';
    v2_terms3 := 'CABLE TRENCHING - LV';
    v2_terms4 := 'OVERHEAD MAINS ADDITIONS - LV';
    v2_terms5 := 'OVERHEAD MAINS REPLACEMENT - LV';
    v2_terms6 := 'SERVICES-OVERHEAD';
    v2_terms7 := 'SERVICES-PUBLIC LIGHTING';
    v2_terms8 := 'SERVICES-TRENCHING';
    v2_terms9 := 'SERVICES-UNDERGROUND';
    v2_terms10 := 'CABLE JOINTING - 33kV';
    v2_terms11 := 'CABLE LAYING - 33kV';
    v2_terms12 := 'CABLE TRENCHING - 33kV';
    v2_terms13 := 'CIVIL WORKS - 33kV';
    v2_terms14 := 'LAND - 33kV';
    v2_terms15 := 'OVERHEAD MAINS ADDITIONS - 33kV';
    v2_terms16 := 'OVERHEAD MAINS REPLACEMENT - 33kV';
    v2_terms17 := 'PLANT + MACHINERY - 33kV';
    v2_terms18 := 'TOWER CONSTRUCTION  - 66kV';
    v2_terms19 := 'TOWER CONSTRUCTION  - 33kV';
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'HV' AND v2_lvl_2 = 'HV' THEN
    v2_terms1 := 'CABLE JOINTING - 11kV';
    v2_terms2 := 'CABLE LAYING - 11kV';
    v2_terms3 := 'CABLE TRENCHING - 11kV';
    v2_terms4 := 'CIVIL WORKS - 11kV';
    v2_terms5 := 'LAND - 11kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 11kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 11kV';
    v2_terms8 := 'PLANT + MACHINERY (GM) - 11kV';
    v2_terms9 := 'PLANT + MACHINERY (PM) - 11kV';
    v2_terms10 := 'PRIMARY SWITCHGEAR - 11kV';
    v2_terms11 := NULL;
    v2_terms12 := NULL;
    v2_terms13 := NULL;
    v2_terms14 := NULL;
    v2_terms15 := NULL;
    v2_terms16 := NULL;
    v2_terms17 := NULL;
    v2_terms18 := NULL;
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'HV' AND v2_lvl_2 = 'EHV' THEN
    v2_terms1 := 'CABLE JOINTING - 11kV';
    v2_terms2 := 'CABLE LAYING - 11kV';
    v2_terms3 := 'CABLE TRENCHING - 11kV';
    v2_terms4 := 'CIVIL WORKS - 11kV';
    v2_terms5 := 'LAND - 11kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 11kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 11kV';
    v2_terms8 := 'PLANT + MACHINERY (GM) - 11kV';
    v2_terms9 := 'PLANT + MACHINERY (PM) - 11kV';
    v2_terms10 := 'PRIMARY SWITCHGEAR - 11kV';
    v2_terms11 := 'CABLE JOINTING - 33kV';
    v2_terms12 := 'CABLE LAYING - 33kV';
    v2_terms13 := 'CABLE TRENCHING - 33kV';
    v2_terms14 := 'CIVIL WORKS - 33kV';
    v2_terms15 := 'LAND - 33kV';
    v2_terms16 := 'OVERHEAD MAINS ADDITIONS - 33kV';
    v2_terms17 := 'OVERHEAD MAINS REPLACEMENT - 33kV';
    v2_terms18 := 'PLANT + MACHINERY - 33kV';
    v2_terms19 := 'TOWER CONSTRUCTION  - 66kV';
    v2_terms20 := 'TOWER CONSTRUCTION  - 33kV';

  ELSIF v2_lvl_1 = 'HV' AND v2_lvl_2 = '132' THEN
    v2_terms1 := 'CABLE JOINTING - 11kV';
    v2_terms2 := 'CABLE LAYING - 11kV';
    v2_terms3 := 'CABLE TRENCHING - 11kV';
    v2_terms4 := 'CIVIL WORKS - 11kV';
    v2_terms5 := 'LAND - 11kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 11kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 11kV';
    v2_terms8 := 'PLANT + MACHINERY (GM) - 11kV';
    v2_terms9 := 'PLANT + MACHINERY (PM) - 11kV';
    v2_terms10 := 'PRIMARY SWITCHGEAR - 11kV';
    v2_terms11 := 'CABLE JOINTING - 132kV';
    v2_terms12 := 'CABLE LAYING - 132kV';
    v2_terms13 := 'CABLE TRENCHING - 132kV';
    v2_terms14 := 'CIVIL WORKS - 132kV';
    v2_terms15 := 'LAND - 132kV';
    v2_terms16 := 'OVERHEAD MAINS ADDITIONS - 132kV';
    v2_terms17 := 'OVERHEAD MAINS REPLACEMENT - 132kV';
    v2_terms18 := 'PLANT + MACHINERY - 132kV';
    v2_terms19 := 'TOWER CONSTRUCTION  - 132kV';
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'EHV' AND v2_lvl_2 = 'EHV' THEN
    v2_terms1 := 'CABLE JOINTING - 33kV';
    v2_terms2 := 'CABLE LAYING - 33kV';
    v2_terms3 := 'CABLE TRENCHING - 33kV';
    v2_terms4 := 'CIVIL WORKS - 33kV';
    v2_terms5 := 'LAND - 33kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 33kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 33kV';
    v2_terms8 := 'PLANT + MACHINERY - 33kV';
    v2_terms9 := 'TOWER CONSTRUCTION  - 66kV';
    v2_terms10 := 'TOWER CONSTRUCTION  - 33kV';
    v2_terms11 := NULL;
    v2_terms12 := NULL;
    v2_terms13 := NULL;
    v2_terms14 := NULL;
    v2_terms15 := NULL;
    v2_terms16 := NULL;
    v2_terms17 := NULL;
    v2_terms18 := NULL;
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = 'EHV' AND v2_lvl_2 = '132' THEN
    v2_terms1 := 'CABLE JOINTING - 33kV';
    v2_terms2 := 'CABLE LAYING - 33kV';
    v2_terms3 := 'CABLE TRENCHING - 33kV';
    v2_terms4 := 'CIVIL WORKS - 33kV';
    v2_terms5 := 'LAND - 33kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 33kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 33kV';
    v2_terms8 := 'PLANT + MACHINERY - 33kV';
    v2_terms9 := 'TOWER CONSTRUCTION  - 66kV';
    v2_terms10 := 'TOWER CONSTRUCTION  - 33kV';
    v2_terms11 := 'CABLE JOINTING - 132kV';
    v2_terms12 := 'CABLE LAYING - 132kV';
    v2_terms13 := 'CABLE TRENCHING - 132kV';
    v2_terms14 := 'CIVIL WORKS - 132kV';
    v2_terms15 := 'LAND - 132kV';
    v2_terms16 := 'OVERHEAD MAINS ADDITIONS - 132kV';
    v2_terms17 := 'OVERHEAD MAINS REPLACEMENT - 132kV';
    v2_terms18 := 'PLANT + MACHINERY - 132kV';
    v2_terms19 := 'TOWER CONSTRUCTION  - 132kV';
    v2_terms20 := NULL;

  ELSIF v2_lvl_1 = '132' AND v2_lvl_2 = '132' THEN
    v2_terms1 := 'CABLE JOINTING - 132kV';
    v2_terms2 := 'CABLE LAYING - 132kV';
    v2_terms3 := 'CABLE TRENCHING - 132kV';
    v2_terms4 := 'CIVIL WORKS - 132kV';
    v2_terms5 := 'LAND - 132kV';
    v2_terms6 := 'OVERHEAD MAINS ADDITIONS - 132kV';
    v2_terms7 := 'OVERHEAD MAINS REPLACEMENT - 132kV';
    v2_terms8 := 'PLANT + MACHINERY - 132kV';
    v2_terms9 := 'TOWER CONSTRUCTION  - 132kV';
    v2_terms10 := NULL;
    v2_terms11 := NULL;
    v2_terms12 := NULL;
    v2_terms13 := NULL;
    v2_terms14 := NULL;
    v2_terms15 := NULL;
    v2_terms16 := NULL;
    v2_terms17 := NULL;
    v2_terms18 := NULL;
    v2_terms19 := NULL;
    v2_terms20 := NULL;

  END IF;

  OPEN get_costs;
  FETCH get_costs
  INTO vn_cost_1,vn_cost_2;
  CLOSE get_costs;

  pn_total_cost := vn_cost_1+vn_cost_2;


EXCEPTION
  WHEN others THEN
    dbms_output.put_line('Error in getting cost'||SQLERRM);

END calc_hcc_costs;

--- conn_letter_all_gen_dual\clagd_new_generate_costs dual.pl ---
PROCEDURE GENERATE_COSTS_DUAL IS

  vn_expenditure_type1_dual       NUMBER;
  vn_expenditure_type2_dual       NUMBER;
  v2_budget_cat_ind_dual		      terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  vn_new_cont_dual                NUMBER;
  vn_new_fees_dual                NUMBER;
  vn_new_non_cont_dual            NUMBER;
  vn_total_cost_dual              NUMBER;
  vn_reg_payment_dual             NUMBER;
  vn_total_charge_dual            NUMBER; 
  vn_vat_rate_dual                NUMBER; 
  vd_date_of_estimate             DATE; 
  vn_terms_split_id_dual		      NUMBER;
  v2_dno                          VARCHAR2(100); 

  CURSOR terms_split_id_dual IS
    SELECT ts.terms_split_id 
      FROM terms_budget_code_for_cat bcfc,
           terms_split ts
     WHERE ts.scheme_id = :parameter.p2_scheme_id_dual
       AND ts.scheme_version = :parameter.p2_scheme_version_dual
       AND ts.terms_budget_cat_id = bcfc.terms_budget_cat_id;    
    
  CURSOR budget_category_dual IS
	  SELECT budget_category_type_ind
	    FROM terms_budget_cat_for_scheme
	   WHERE scheme_id = :parameter.p2_scheme_id_dual
	     AND scheme_version = :parameter.p2_scheme_version_dual;  

  CURSOR get_fees_dual Is
    SELECT SUM(ROUND( sbfm.fees_cost )) fees
      FROM scheme_breakdown_for_margins sbfm, 
           cost_item ci, 
           work_category_for_scheme wcfs,
           work_category wc,
           historic_swe hs
     WHERE sbfm.cost_item_id = ci.cost_item_id
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       AND wcfs.work_category_2(+) = wc.work_category
       AND sbfm.fees_cost > 0 
       AND sbfm.description = 'FEES'
       AND sbfm.standard_work_element_id = hs.standard_work_element_id
       AND hs.date_to IS NULL
       AND sbfm.scheme_id = wcfs.scheme_id
       AND sbfm.scheme_version = wcfs.scheme_version
       AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
       AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
       AND sbfm.userid = user_pk.get_userid
     GROUP BY wc.work_category, wc.description_for_customer;

  CURSOR get_date_of_estimate IS
    SELECT DISTINCT date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id_dual
       AND scheme_version = :parameter.p2_scheme_version_dual;
     
  CURSOR new_costs_dual IS
    SELECT  DISTINCT 
              1, 
              NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
              NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
              NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(non_cont.quantity,0) + NVL(cont.quantity,0)  total_quantity,
              NVL(swe.description_for_customer,ci.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id 
         FROM scheme_breakdown_for_margins sbfm,
              cost_item ci,
              cost_item_element cie,
              cost_item_element	non_cont,
              cost_item_element	cont,
              work_category_for_scheme wcfs,
              standard_work_element swe,
              work_category wc,
              work_category_association wca,
              budget_code_for_scheme_split bcfss,
              budget_code bc,
             (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
               WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                 AND rsi1.CONTINGENCY_IND = 'Y') ts
        WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
          AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
          AND sbfm.userid = user_pk.get_userid
          AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
          AND ts.scheme_id(+) = sbfm.scheme_id
          AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
          AND ci.cost_item_id = sbfm.cost_item_id
          AND ci.cost_item_indicator != 'T'
          AND cie.cost_item_id = ci.cost_item_id
          AND cie.budget_code IS NULL
          AND swe.standard_work_element_id(+) = ci.standard_work_element_id
          AND bcfss.scheme_id = sbfm.scheme_id
          AND bcfss.scheme_version = sbfm.scheme_version
          AND bc.budget_code = bcfss.budget_code
          AND bc.date_from = bcfss.budget_code_date_from
          AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
          AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
          AND wc.work_category = wcfs.work_category_1
          AND wca.work_category_1(+) = wcfs.work_category_1
          AND wca.work_category_2(+) = wcfs.work_category_2
          AND non_cont.cost_item_id(+) = sbfm.cost_item_id
          AND non_cont.type_of_cost_ri(+) = 206
          AND cont.cost_item_id(+) = sbfm.cost_item_id
          AND cont.type_of_cost_ri(+) = 207
          AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
        UNION
       SELECT DISTINCT 
                1, 
                NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
                NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                NVL(swe.description_for_customer,ci.description) swe_description,
                sbfm.description,
                sbfm.cost_item_id
           FROM scheme_breakdown_for_margins sbfm,
                cost_item ci,
                work_category_for_scheme wcfs,
                cost_item_element non_cont,
                cost_item_element cont,
                standard_work_element swe,
                work_category_association wca,
                work_category wc,
                cost_item_allocation$v cia,
               (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                  FROM terms_split ts1, recharge_statement_info rsi1 
                 WHERE ts1.terms_split_id = rsi1.terms_split_id
                   AND rsi1.CONTINGENCY_IND = 'Y') ts
          WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
            AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
            AND sbfm.userid = user_pk.get_userid AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
            AND ts.scheme_id(+) = sbfm.scheme_id
            AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
            AND ci.cost_item_id = sbfm.cost_item_id
            AND ci.cost_item_indicator != 'T'
            AND cia.cost_item_id = ci.cost_item_id
            AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
            AND cia.split_indicator = 0
            AND swe.standard_work_element_id(+) = ci.standard_work_element_id
            AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
            AND wc.work_category = wcfs.work_category_1
            AND wca.work_category_1(+) = wcfs.work_category_1
            AND wca.work_category_2(+) = wcfs.work_category_2
            AND non_cont.cost_item_id(+) = ci.cost_item_id
            AND non_cont.type_of_cost_ri(+) = 206
            AND cont.cost_item_id(+) = ci.cost_item_id
            AND cont.type_of_cost_ri(+) = 207
          UNION
         SELECT DISTINCT 
                  1, 
                  NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                  NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                  NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
                  NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                  NVL(swe.description_for_customer,cip.description) swe_description,
                  sbfm.description,
                  sbfm.cost_item_id
           FROM scheme_breakdown_for_margins sbfm,
                cost_item ci,
                work_category_for_scheme wcfs,
                cost_item_element non_cont,
                cost_item_element cont,
                standard_work_element swe,
                work_category_association wca,
                work_category wc,
                cost_item_allocation$v cia,
                cost_item cip,
               (SELECT rsi1.contingency_ind "CONTINGENCY_IND" ,rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version 
                  FROM terms_split ts1, recharge_statement_info rsi1 
                 WHERE ts1.terms_split_id = rsi1.terms_split_id
                   AND rsi1.contingency_ind = 'Y') ts
          WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
            AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
            AND sbfm.userid = user_pk.get_userid
            AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
            AND ts.scheme_id(+) = sbfm.scheme_id
            AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
            AND cip.cost_item_id = sbfm.cost_item_id
            AND cip.cost_item_indicator != 'T'
            AND ci.parent_cost_item_id = cip.cost_item_id
            AND cia.cost_item_id = ci.cost_item_id
            AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
            AND cia.split_indicator = 0
            AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
            AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
            AND wc.work_category = wcfs.work_category_1
            AND wca.work_category_1(+) = wcfs.work_category_1
            AND wca.work_category_2(+) = wcfs.work_category_2
            AND non_cont.cost_item_id(+) = sbfm.cost_item_id
            AND non_cont.type_of_cost_ri(+) = 206
            AND cont.cost_item_id(+) = sbfm.cost_item_id
            AND cont.type_of_cost_ri(+) = 207
          UNION
         SELECT 2, 
                sum(CONTESTABLE_COST), 
                sum(NONCONTESTABLE_COST), 
                work_cat_desc,total_quantity, 
                'Travel', 
                budget_code,work_cat_for_scheme_id 
          FROM (SELECT  DISTINCT 
                          2, 
                          DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                          DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.noncont_travel_cost,2),ROUND(sbfm.noncont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                          NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                          0 total_quantity,
                          'Travel',
                          bc.budget_code, 
                          wcfs.work_cat_for_scheme_id
                   FROM travel_cost_for_margins sbfm,
                        work_category_for_scheme wcfs,
                        work_category_association wca,
                        BUDGET_CODE BC,
                        work_category wc,
                        cost_item ci,
                       (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                          FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                         WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                           AND rsi1.CONTINGENCY_IND = 'Y') ts			      
                  WHERE wc.work_category(+) = wcfs.work_category_2
                    AND wca.work_category_1(+) = wcfs.work_category_1
                    AND wca.work_category_2(+) = wcfs.work_category_2
                    AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                    AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                    AND ci.scheme_id = sbfm.scheme_id
                    AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                    AND ci.COST_ITEM_INDICATOR = 'T'
                    AND ts.scheme_id(+) = sbfm.scheme_id
                    AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                    AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                    AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                    AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                    AND sbfm.scheme_id = wcfs.scheme_id
                    AND sbfm.scheme_version = wcfs.scheme_version
                    AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                    AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                    AND sbfm.userid = user_pk.get_userid   
                  UNION
                 SELECT DISTINCT 
                          2, 
                          ROUND(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
                          0 NONCONTESTABLE_COST,
                          NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                          0 total_quantity,
                          'Travel',
                          bc.budget_code, 
                          wcfs.work_cat_for_scheme_id
                   FROM travel_cost_for_margins sbfm,
                        work_category_for_scheme wcfs,
                        work_category_association wca,
                        BUDGET_CODE BC,
                        work_category wc,
                        cost_item ci,
                        scheme_version sv,
                        budget_code_margin_applicable bcma,
                       (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                          FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                         WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                           AND rsi1.CONTINGENCY_IND = 'Y') ts			      
                   WHERE wc.work_category(+) = wcfs.work_category_2
                     AND wca.work_category_1(+) = wcfs.work_category_1
                     AND wca.work_category_2(+) = wcfs.work_category_2
                     AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                     AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                     AND ci.scheme_id = sbfm.scheme_id
                     AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                     AND ci.COST_ITEM_INDICATOR = 'T'
                     AND ts.scheme_id(+) = sbfm.scheme_id
                     AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                     AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                     AND sbfm.budget_code = bcma.budget_code
                     AND sbfm.engineering_classification = bcma.engineering_classification
                     AND bcma.dno = v2_dno
                     AND sbfm.budget_code_date_from = bc.date_from            
                     AND sbfm.budget_code_date_from = bcma.budget_code_date_from                
                     AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
                     AND sv.scheme_id = sbfm.scheme_id
                     AND sv.scheme_version = sbfm.scheme_version
                     AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                     AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                     AND sbfm.scheme_id = wcfs.scheme_id
                     AND sbfm.scheme_version = wcfs.scheme_version
                     AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                     AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                     AND sbfm.userid = user_pk.get_userid
                )
         GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;
 
  CURSOR terms_recovered_asset_dual IS
    SELECT DISTINCT (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           terms_budget_code_for_cat TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.p2_scheme_version_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID; 
       
  CURSOR user_applied_terms_vat_dual IS
    SELECT quantity
      FROM terms_general_standard
     WHERE terms_general_standard_id IN (SELECT t.TERMS_GENERAL_STANDARD_ID 
                                           FROM terms_general_standard t
                                          WHERE t.TERMS_GENERAL_STANDARD_ID IN (SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                  FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri = 1339
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL 
                                                                                   AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
                                                                                   AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
                                                                                 UNION
                                                                                SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                  FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri     =1339
                                                                                   AND t.terms_standard_ri =1337
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL
                                                                                   AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
                                                                                   AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
                                                                                   AND NOT EXISTS (SELECT 1 
                                                                                                     FROM USER_APPL_TERMS_GEN_STAN 
                                                                                                    WHERE TERMS_SPLIT_ID = vn_terms_split_id_dual)
                                                                                )
                                          ); 

BEGIN

  v2_dno := crown_owner.util_scheme_procs.get_dno_for_scheme(:Parameter.p2_scheme_id_dual, :Parameter.p2_scheme_version_dual);

  -- Populate table with costs for dual offer
  OPEN terms_split_id_dual;
  FETCH terms_split_id_dual
  INTO vn_terms_split_id_dual;
  CLOSE terms_split_id_dual;

	OPEN budget_category_dual;
	FETCH budget_category_dual
	INTO v2_budget_cat_ind_dual;
	CLOSE budget_category_dual;
	
  IF v2_budget_cat_ind_dual IN ('E','N')  THEN
    vn_expenditure_type1_dual := 226;
    vn_expenditure_type2_dual := 227;
  ELSE
    vn_expenditure_type1_dual := 258;
  END IF;  

  IF vn_expenditure_type1_dual = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid,vn_expenditure_type1_dual);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid);    
  END IF;

  -- get fees
  vn_new_cont_dual :=0;
  vn_new_fees_dual :=0;
  vn_new_non_cont_dual :=0;
  vn_total_cost_dual :=0;
  vn_reg_payment_dual :=0;
  vn_total_charge_dual := 0;
    
  FOR get_rec IN get_fees_dual LOOP
    vn_new_fees_dual := vn_new_fees_dual+get_rec.fees;
  END LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_2 := vn_new_fees_dual;

  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
  


  -- get non-contestable costs
  FOR get_rec IN new_costs_dual LOOP
  	vn_new_cont_dual := vn_new_cont_dual+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont_dual := vn_new_non_conT_dual+get_rec.NONCONTESTABLE_COST;
  END LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_2 := vn_new_non_cont_dual;

  -- get ECCR payment
  OPEN terms_recovered_asset_dual;
	FETCH terms_recovered_asset_dual
  INTO vn_reg_payment_dual;
	CLOSE terms_recovered_asset_dual;
	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_2 := vn_reg_payment_dual;

  -- get connection charge ex vat
  vn_total_charge_dual := NVL(vn_new_cont_dual,0)+NVL(vn_new_non_cont_dual,0)+NVL(vn_new_fees_dual,0)+NVL(vn_reg_payment_dual,0);

	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_2 := vn_total_charge_dual;
  
  -- get vat amount
  FOR get_rec IN user_applied_terms_vat_dual LOOP
   	vn_vat_rate_dual := NULL;     	   	
  	vn_vat_rate_dual := get_rec.quantity;
  END LOOP;

  :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := ROUND(vn_vat_rate_dual*NVL(vn_total_charge_dual,0),2)/100;
  SYNCHRONIZE;

  -- get connection charge inc vat
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_2 := ROUND(NVL(:TERMS_CONNECTION_LETTERS_SBK.VAT_2,0)+vn_total_charge_dual,2);

  COMMIT;
	GO_BLOCK('TERMS_CONNECTION_LETTERS_SBK');
	EXECUTE_QUERY;

END;

--- conn_letter_all_gen_dual\clagd_new_generate_costs.pl ---
PROCEDURE generate_costs IS

  vn_expenditure_type1      NUMBER;
  vn_expenditure_type2      NUMBER;
  v2_budget_cat_ind		      terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  vn_new_cont               NUMBER;
  vn_new_non_cont           NUMBER;
  vn_total_cost             NUMBER;
  vn_reg_payment            NUMBER;
  vn_total_charge           NUMBER;
  vn_new_fees               NUMBER;
  vn_vat_rate							  NUMBER;
  vd_date_of_estimate       DATE;
  vn_terms_split_id		      NUMBER;
  vn_pre_vat_text           VARCHAR2(250);
  vn_vat_total_text         VARCHAR2(250);
  v2_dno                    VARCHAR2(100);

  CURSOR terms_split_id IS
    SELECT ts.terms_split_id
      FROM terms_budget_code_for_cat bcfc,
           terms_split ts
     WHERE ts.scheme_id = :parameter.p2_scheme_id_full
       AND ts.scheme_version = :parameter.p2_scheme_version_full
       AND ts.terms_budget_cat_id = bcfc.terms_budget_cat_id;

 	CURSOR budget_category IS
	  SELECT budget_category_type_ind
	    FROM terms_budget_cat_for_scheme
	   WHERE scheme_id = :parameter.p2_scheme_id_full
	     AND scheme_version = :parameter.p2_scheme_version_full;

  CURSOR get_date_of_estimate IS
    SELECT DISTINCT date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id_full
       AND scheme_version = :parameter.p2_scheme_version_full;

  CURSOR c_new_costs IS
    SELECT DISTINCT
            1,
            NVL(DECODE(NVL(ts.contingency_ind,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
            NVL(DECODE(NVL(ts.contingency_ind,'N'),'N',ROUND(sbfm.noncontestable_cost*bcfss.percentage_split/100,2),ROUND(sbfm.noncontestable_cost*bcfss.percentage_split/100,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST,
            NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
            NVL(cie_non_cont.quantity,0)+NVL(cont.quantity,0)  total_quantity,
            NVL(swe.description_for_customer,ci.description) swe_description,
            sbfm.description,
            sbfm.cost_item_id
     FROM scheme_breakdown_for_margins sbfm,
          cost_item ci,
          cost_item_element cie,
          cost_item_element	cie_non_cont,
          cost_item_element	cont,
          work_category_for_scheme wcfs,
          standard_work_element swe,
          work_category wc,
          work_category_association wca,
          budget_code_for_scheme_split bcfss,
          budget_code bc,
         (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
            FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
           WHERE ts1.terms_split_id = rsi1.terms_split_id
             AND rsi1.CONTINGENCY_IND = 'Y') ts
    WHERE sbfm.scheme_id = :parameter.p2_scheme_id_full
      AND sbfm.scheme_version = :parameter.p2_scheme_version_full
      AND sbfm.userid = user_pk.get_userid
      AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
      AND ts.scheme_id(+) = sbfm.scheme_id
      AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
      AND ci.cost_item_id = sbfm.cost_item_id
      AND ci.cost_item_indicator != 'T'
      AND cie.cost_item_id = ci.cost_item_id
      AND cie.budget_code IS NULL
      AND swe.standard_work_element_id(+) = ci.standard_work_element_id
      AND bcfss.scheme_id = sbfm.scheme_id
      AND bcfss.scheme_version = sbfm.scheme_version
      AND bc.budget_code = bcfss.budget_code
      AND bc.date_from = bcfss.budget_code_date_from
      AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
      AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
      AND wc.work_category = wcfs.work_category_1
      AND wca.work_category_1(+) = wcfs.work_category_1
      AND wca.work_category_2(+) = wcfs.work_category_2
      AND cie_non_cont.cost_item_id(+) = sbfm.cost_item_id
      AND cie_non_cont.type_of_cost_ri(+) = 206
      AND cont.cost_item_id(+) = sbfm.cost_item_id
      AND cont.type_of_cost_ri(+) = 207
      AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
    UNION
   SELECT DISTINCT
            1,
            NVL(DECODE(NVL(ts.contingency_ind,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
            NVL(DECODE(NVL(ts.contingency_ind,'N'),'N',ROUND(sbfm.noncontestable_cost,2),ROUND(sbfm.noncontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncontestable_cost,2)),0) NONCONTESTABLE_COST,
            NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
            NVL(cie_non_cont.quantity,0)+NVL(cont.quantity,0) total_quantity,
            NVL(swe.description_for_customer,ci.description) swe_description,
            sbfm.description,
            sbfm.cost_item_id
       FROM scheme_breakdown_for_margins sbfm,
            cost_item ci,
            work_category_for_scheme wcfs,
            cost_item_element cie_non_cont,
            cost_item_element cont,
            standard_work_element swe,
            work_category_association wca,
            work_category wc,
            cost_item_allocation$v cia,
           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
             WHERE ts1.terms_split_id = rsi1.terms_split_id
               AND rsi1.CONTINGENCY_IND = 'Y') ts
      WHERE sbfm.scheme_id = :parameter.p2_scheme_id_full
        AND sbfm.scheme_version = :parameter.p2_scheme_version_full
        AND sbfm.userid = user_pk.get_userid
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND ci.cost_item_id = sbfm.cost_item_id
        AND ci.cost_item_indicator != 'T'
        AND cia.cost_item_id = ci.cost_item_id
        AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
        AND cia.split_indicator = 0
        AND swe.standard_work_element_id(+) = ci.standard_work_element_id
        AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND cie_non_cont.cost_item_id(+) = ci.cost_item_id
        AND cie_non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = ci.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
      UNION
     SELECT DISTINCT
              1,
              NVL(DECODE(NVL(ts.contingency_ind,'N'),'N',ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
              NVL(DECODE(NVL(ts.contingency_ind,'N'),'N',ROUND(sbfm.noncontestable_cost,2),ROUND(sbfm.noncontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncontestable_cost,2)),0) NONCONTESTABLE_COST,
              NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(cie_non_cont.quantity,0)+NVL(cont.quantity,0) total_quantity,
              NVL(swe.description_for_customer,cip.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id
       FROM scheme_breakdown_for_margins sbfm,
            cost_item ci,
            work_category_for_scheme wcfs,
            cost_item_element cie_non_cont,
            cost_item_element cont,
            standard_work_element swe,
            work_category_association wca,
            work_category wc,
            cost_item_allocation$v cia,
            cost_item cip,
           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
             WHERE ts1.terms_split_id = rsi1.terms_split_id
               AND rsi1.CONTINGENCY_IND = 'Y') ts
      WHERE sbfm.scheme_id = :parameter.p2_scheme_id_full
        AND sbfm.scheme_version = :parameter.p2_scheme_version_full
        AND sbfm.userid = user_pk.get_userid
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND cip.cost_item_id = sbfm.cost_item_id
        AND cip.cost_item_indicator != 'T'
        AND ci.parent_cost_item_id = cip.cost_item_id
        AND cia.cost_item_id = ci.cost_item_id
        AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
        AND cia.split_indicator = 0
        AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
        AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND cie_non_cont.cost_item_id(+) = sbfm.cost_item_id
        AND cie_non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = sbfm.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
      UNION
     SELECT 2,
            sum(CONTESTABLE_COST),
            sum(NONCONTESTABLE_COST),
            work_cat_desc,
            total_quantity,
            'Travel',
            budget_code,
            work_cat_for_scheme_id
       FROM (SELECT DISTINCT
                      2,
                      DECODE(NVL(ts.contingency_ind,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                      DECODE(NVL(ts.contingency_ind,'N'),'N',ROUND(sbfm.noncont_travel_cost,2),ROUND(sbfm.noncont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                      NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                      0 total_quantity,
                      'Travel',
                      bc.budget_code,
                      wcfs.work_cat_for_scheme_id
               FROM travel_cost_for_margins sbfm,
                    work_category_for_scheme wcfs,
                    work_category_association wca,
                    BUDGET_CODE BC,
                    work_category wc,
                    cost_item ci,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                      FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                     WHERE ts1.terms_split_id = rsi1.terms_split_id
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE wc.work_category(+) = wcfs.work_category_2
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND ci.scheme_id = sbfm.scheme_id
                AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                AND ci.COST_ITEM_INDICATOR = 'T'
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                AND sbfm.scheme_id = wcfs.scheme_id
                AND sbfm.scheme_version = wcfs.scheme_version
                AND sbfm.scheme_id = :parameter.p2_scheme_id_full
                AND sbfm.scheme_version = :parameter.p2_scheme_version_full
                AND sbfm.userid = user_pk.get_userid
              UNION
             SELECT DISTINCT
                      2,
                      ROUND(DECODE(NVL(ts.contingency_ind,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2)) * bcma.margin / 100,2) CONTESTABLE_COST,
                      0 NONCONTESTABLE_COST,
                      NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                      0 total_quantity,
                      'Travel',
                      bc.budget_code,
                      wcfs.work_cat_for_scheme_id
               FROM travel_cost_for_margins sbfm,
                    work_category_for_scheme wcfs,
                    work_category_association wca,
                    BUDGET_CODE BC,
                    work_category wc,
                    cost_item ci,
                    scheme_version sv,
                    budget_code_margin_applicable bcma,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                      FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                     WHERE ts1.terms_split_id = rsi1.terms_split_id
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE wc.work_category(+) = wcfs.work_category_2
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND (sbfm.cont_travel_cost > 0 or sbfm.noncont_travel_cost >0)
                AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND ci.scheme_id = sbfm.scheme_id
                AND ci.scheme_version = sbfm.scheme_version
                AND ci.cost_item_indicator = 'T'
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.scheme_version
                AND sbfm.budget_code = bc.budget_code
                AND sbfm.budget_code = bcma.budget_code
                AND sbfm.engineering_classification = bcma.engineering_classification
                AND bcma.dno = v2_dno
                AND sbfm.budget_code_date_from = bc.date_from            
                AND sbfm.budget_code_date_from = bcma.budget_code_date_from                
                AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
                AND sv.scheme_id = sbfm.scheme_id
                AND sv.scheme_version = sbfm.scheme_version
                AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                AND sbfm.scheme_id = wcfs.scheme_id
                AND sbfm.scheme_version = wcfs.scheme_version
                AND sbfm.scheme_id = :parameter.p2_scheme_id_full
                AND sbfm.scheme_version = :parameter.p2_scheme_version_full
                AND sbfm.userid = user_pk.get_userid)
              GROUP by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  CURSOR terms_recovered_asset IS
    SELECT DISTINCT (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.P2_SCHEME_ID_full
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_full
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_date_from=BC.date_from
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;

  CURSOR get_fees IS
    SELECT sum(ROUND(sbfm.fees_cost)) FEES
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           work_category wc,
           historic_swe hs
     WHERE sbfm.cost_item_id = ci.cost_item_id
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       AND wcfs.work_category_2(+) = wc.work_category
       AND sbfm.fees_cost > 0
       AND sbfm.description = 'FEES'
       AND sbfm.standard_work_element_id = hs.standard_work_element_id
       AND hs.date_to is null
       AND sbfm.scheme_id = wcfs.scheme_id
       AND sbfm.scheme_version = wcfs.scheme_version
       AND sbfm.scheme_id = :parameter.P2_SCHEME_ID_full
       AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_full
       AND sbfm.userid = user_pk.get_userid
     GROUP BY wc.work_category, wc.description_for_customer;


  CURSOR user_applied_terms_vat IS
    SELECT quantity
      FROM terms_general_standard
     WHERE terms_general_standard_id IN (SELECT t.terms_general_standard_id
                                           FROM terms_general_standard t
                                          WHERE t.terms_general_standard_id IN (SELECT t.terms_general_standard_id
                                                                                  FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri = 1339
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL
                                                                                   AND t.terms_general_standard_id = u.terms_general_standard_id
                                                                                   AND u.terms_split_id(+) = vn_terms_split_id
                                                                                 UNION
                                                                                SELECT t.terms_general_standard_id
                                                                                  FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri     =1339
                                                                                   AND t.terms_standard_ri =1337
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL
                                                                                   AND t.terms_general_standard_id = u.terms_general_standard_id(+)
                                                                                   AND u.terms_split_id(+)= vn_terms_split_id
                                                                                   AND NOT EXISTS (SELECT 1
                                                                                                     FROM USER_APPL_TERMS_GEN_STAN
                                                                                                     WHERE terms_split_id = vn_terms_split_id)
                                                                                )
                                        );

BEGIN

  v2_dno := crown_owner.util_scheme_procs.get_dno_for_scheme(:parameter.p2_scheme_id_full, :parameter.p2_scheme_version_full);

  -- Populate table with costs for main scheme
  OPEN terms_split_id;
  FETCH terms_split_id
  INTO vn_terms_split_id;
  CLOSE terms_split_id;

	OPEN budget_category;
	FETCH budget_category
	INTO v2_budget_cat_ind;
	CLOSE budget_category;

  IF v2_budget_cat_ind IN ('E','N')  THEN
    vn_expenditure_type1 := 226;
    vn_expenditure_type2 := 227;
  ELSE
    vn_expenditure_type1 := 258;
  END IF;

  IF vn_expenditure_type1 = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_full,:PARAMETER.P2_SCHEME_VERSION_FULL,user_pk.get_userid,vn_expenditure_type1);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_full,:PARAMETER.P2_SCHEME_VERSION_FULL,user_pk.get_userid);
  END IF;

  -- get fees
  vn_new_cont     :=0;
  vn_new_fees     :=0;
  vn_new_non_cont :=0;
  vn_total_cost   :=0;
  vn_reg_payment  :=0;
  vn_total_charge :=0;

  FOR get_rec IN get_fees LOOP
    vn_new_fees := vn_new_fees+get_rec.fees;
  END LOOP;

  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_1 := vn_new_fees;

  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;

  -- get non-contestable costs
  FOR get_rec IN c_new_costs LOOP
  	vn_new_cont := vn_new_cont+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont := vn_new_non_cont+get_rec.NONCONTESTABLE_COST;
  END LOOP;

  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_1 := vn_new_non_cont;

  -- get contestable costs
  :TERMS_CONNECTION_LETTERS_SBK.CONTESTABLE_WORKS_1 := vn_new_cont;

  -- get ECCR payment
  OPEN terms_recovered_asset;
	FETCH terms_recovered_asset
  INTO vn_reg_payment;
	CLOSE terms_recovered_asset;

	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_1 := vn_reg_payment;

  -- get connection charge ex vat
  vn_total_charge := NVL(vn_new_cont,0)+NVL(vn_new_non_cont,0)+NVL(vn_new_fees,0)+NVL(vn_reg_payment,0);
	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_1 := vn_total_charge;

  -- get vat amount
  FOR get_rec IN user_applied_terms_vat LOOP
   	vn_vat_rate := NULL;
   	vn_vat_rate := get_rec.quantity;
  END LOOP;

  :TERMS_CONNECTION_LETTERS_SBK.VAT_1 := ROUND(vn_vat_rate*NVL(vn_total_charge,0),2)/100;
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_1 := ROUND(NVL(:TERMS_CONNECTION_LETTERS_SBK.VAT_1,0)+vn_total_charge,2);

  COMMIT;

  go_block('TERMS_CONNECTION_LETTERS_SBK');
	execute_query;

END;

--- conn_letter_all_gen_dual\clagd_old_generate_costs dual.pl ---
PROCEDURE GENERATE_COSTS_DUAL IS
		vn_alert 				NUMBER;

  vn_expenditure_type1_dual NUMBER;
  vn_expenditure_type2_dual NUMBER;

  v2_budget_cat_ind_dual		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;


--
-- dual offer cursors
-- 

    vn_new_cont_dual NUMBER;
    vn_new_fees_dual NUMBER;
    vn_new_non_cont_dual NUMBER;
    vn_total_cost_dual NUMBER;
    vn_reg_payment_dual NUMBER;
    vn_total_charge_dual NUMBER; 
    vn_vat_rate_dual number;
 --   vn_terms_split_id_dual		 number;     
    
      CURSOR terms_split_id_dual IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;    
    

  	CURSOR budget_category_dual IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;  

  CURSOR get_fees_dual Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id_dual
       AND scheme_version = :parameter.p2_scheme_version_dual;
     
  vd_date_of_estimate DATE; 
  v2_quantity NUMBER(3);
  
  CURSOR get_quantity IS
  SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
AND trunc(vd_date_of_estimate) BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate)); 


    CURSOR new_costs_dual IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  vn_past_code_amount_dual   	NUMBER;     
  CURSOR terms_recovered_asset_dual IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.p2_scheme_version_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID; 
       
--CCN10061 Start bc/vat rate changes dual

  vn_budget_code_dual	     varchar2(3);
  vn_cost_per_bc_dual       number;
  vn_cost_per_customer_dual number;
  vn_total_customers_dual   number;
  vn_cost_per_vat_rate_dual number;
  vn_total_cost_vat_dual    number;
  vn_terms_split_id_dual		 number;
  vn_pre_vat_text_dual      VARCHAR2(250);
  vn_vat_total_text_dual    VARCHAR2(250);
  vn_pre_vat_text_final_dual      VARCHAR2(500);
  vn_vat_total_text_final_dual    VARCHAR2(500);
  vn_vat_total_cost_dual    number;
  vn_loop_counter NUMBER;
      
CURSOR get_vat_total_amount_dual IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code_dual
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
AND bc.budget_code = vn_budget_code_dual
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
AND bc.budget_code = vn_budget_code_dual
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code_dual
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
       AND BC.BUDGET_CODE = vn_budget_code_dual
       AND 1 = vn_loop_counter
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code_dual IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id_dual
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

  vn_cust_per_vat_rate_dual NUMBER;

  CURSOR user_applied_terms_vat_dual IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_dual))); 
     
     
     CURSOR get_vat IS
       SELECT sum(ROUND(vat_total_cost,2))
         FROM conn_letter_budget_vat
        WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
          AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;
         
     
--CCN10061 End bc/vat rate changes dual


BEGIN



--
-- Populate table with costs for dual offer
--

    OPEN terms_split_id_dual;
    FETCH terms_split_id_dual
    INTO vn_terms_split_id_dual;
    CLOSE terms_split_id_dual;

	OPEN budget_category_dual;
	FETCH budget_category_dual
	INTO v2_budget_cat_ind_dual;
	CLOSE budget_category_dual;
	

	
  IF v2_budget_cat_ind_dual IN ('E','N')  THEN
    vn_expenditure_type1_dual := 226;
    vn_expenditure_type2_dual := 227;
  ELSE
    vn_expenditure_type1_dual := 258;
  END IF;  


  IF vn_expenditure_type1_dual = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid,vn_expenditure_type1_dual);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid);    
  END IF;
 -- commit;
  

--
-- get fees
--
    vn_new_cont_dual :=0;
    vn_new_fees_dual :=0;
    vn_new_non_cont_dual :=0;
    vn_total_cost_dual :=0;
    vn_reg_payment_dual :=0;
    vn_total_charge_dual := 0;
    
  for get_rec IN get_fees_dual LOOP
    vn_new_fees_dual := vn_new_fees_dual+get_rec.fees;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_2 := vn_new_fees_dual;

  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
  
  OPEN get_quantity;
  FETCH get_quantity
  INTO v2_quantity;
  CLOSE get_quantity;

  
--
-- get non-contestable costs
--
  for get_rec IN new_costs_dual LOOP
  	vn_new_cont_dual := vn_new_cont_dual+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont_dual := vn_new_non_conT_dual+get_rec.NONCONTESTABLE_COST;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_2 := vn_new_non_cont_dual;
--
-- get ECCR payment
--
  OPEN terms_recovered_asset_dual;
	FETCH terms_recovered_asset_dual
  INTO vn_reg_payment_dual;
	CLOSE terms_recovered_asset_dual;
	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_2 := vn_reg_payment_dual;
	
-- 
-- get connection charge ex vat
--
  vn_total_charge_dual := NVL(vn_new_cont_dual,0)+NVL(vn_new_non_cont_dual,0)+NVL(vn_new_fees_dual,0)+NVL(vn_reg_payment_dual,0);

	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_2 := vn_total_charge_dual;
  
--
-- get vat amount
--

--
-- CCN10061 start bc/vat split daul
--

--  delete from conn_letter_budget_vat
--  where scheme_id = :PARAMETER.P2_SCHEME_ID_dual
--    and scheme_version = :PARAMETER.P2_SCHEME_VERSION_dual;
--  commit;


--open cursor to get number of budget codes and loop round for each one
--	vn_vat_total_cost_dual := 0;
--	vn_total_cost_vat_dual := 0;
--	vn_pre_vat_text_final := NULL;
--	vn_vat_total_text_final := NULL;
--vn_loop_counter := 1;

--	vn_total_customers_dual :=0;
	
--  FOR get_rec IN get_budget_code_dual LOOP
--  	vn_cost_per_bc_dual := 0;
--  	vn_budget_code_dual := NULL;
--  	vn_total_customers_dual := NULL;
--  	vn_terms_split_id_dual := NULL;
  	
--  	vn_budget_code_dual := get_rec.budget_code;
--    vn_total_customers_dual := get_rec.number_of_connections;
--    vn_terms_split_id_dual := get_rec.terms_split_id;

--open cursor to get vat_total_amount

--    OPEN get_vat_total_amount_dual;
--    FETCH get_vat_total_amount_dual
--    INTO vn_cost_per_bc_dual;
--    CLOSE get_vat_total_amount_dual;
    
--if cost is greater then 0 carry on
--    IF vn_cost_per_bc_dual >0 THEN
    	
--use number of connections to divide the vn_total_amount into vn_cost_per_customer    	
--      vn_cost_per_customer_dual := round(vn_cost_per_bc_dual/vn_total_customers_dual,2);
--open cursor user_applied_terms_vat to get vat_rate and number of quantity at vat rate and loop      
      FOR get_rec IN user_applied_terms_vat_dual LOOP
 --     	vn_total_customers := NULL;
      	vn_vat_rate_dual := NULL;     	
     --   vn_cust_per_vat_rate_dual := NULL;	     	
      	
      --     	vn_total_customers := get_rec.customers;
           	vn_vat_rate_dual := get_rec.quantity;
     --multiply the number of connections with vn_cost_per_customer into vn_cust_per_vat_rate      	
--           	vn_cost_per_vat_rate_dual := round(vn_cost_per_customer_dual*vn_total_customers_dual,2);
           	--multiply vn_cost_per_vat_rate with vat rate to get vn_total_cost_vat rate
--             vn_total_cost_vat_dual := round(vn_vat_rate_dual*vn_cost_per_vat_rate_dual,2)/100;
     --if more then one vat rate concat vn_total

--	      insert into conn_letter_budget_vat(scheme_id,scheme_version,budget_code,vat_rate,total_cost,vat_total_cost)
--	      values(:parameter.p2_scheme_id_dual,:parameter.P2_SCHEME_VERSION_dual,vn_budget_code_dual,vn_vat_rate_dual,vn_cost_per_vat_rate_dual,vn_total_cost_vat_dual);
--	      commit;
--	      vn_loop_counter := vn_loop_counter+1;
	       
--	      vn_vat_total_cost_dual := vn_vat_total_cost_dual+vn_total_cost_vat_dual;
      
      END LOOP;
--    END IF;
--END LOOP;

  :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := round(vn_vat_rate_dual*nvl(vn_total_charge_dual,0),2)/100;

--		  synchronize;
    
--	    UPDATE TERMS_CONNECTION_LETTERS
--	      SET VAT_2 = NVL(TRUNC(vn_vat_total_cost_dual,2),0)
--	    WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
--	      AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;
--	    COMMIT;
--	    Go_block('TERMS_CONNECTION_LETTERS_SBK');
--		  execute_query;
		  synchronize;
		  
--		  :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := NVL(vn_vat_total_cost_dual,0);
--	    COMMIT;
--	    Go_block('TERMS_CONNECTION_LETTERS_SBK');
--		  execute_query;
		  		  
		  
--
-- CCN10061 end bc/vat split dual
--  


--
-- get connection charge inc vat
--
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_2 := round(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_2,0)+vn_total_charge_dual,2);


  commit;
		go_block('TERMS_CONNECTION_LETTERS_SBK');
		execute_query;

END;

--- conn_letter_all_gen_dual\clagd_old_generate_costs.pl ---
PROCEDURE generate_costs IS
		vn_alert 				NUMBER;
  vn_expenditure_type1 NUMBER;
  vn_expenditure_type2 NUMBER;
  vn_expenditure_type1_dual NUMBER;
  vn_expenditure_type2_dual NUMBER;
  v2_budget_cat_ind		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  v2_budget_cat_ind_dual		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
 -- vn_terms_split_id		 number;  
  vn_new_cont number;
  vn_new_non_cont number;   
  vn_total_cost number; 
  vn_reg_payment NUMBER;
  vn_total_charge NUMBER;
  vn_new_fees NUMBER;
  vn_vat_rate							NUMBER;
  
  
--
-- get main costs cursors
--
      CURSOR terms_split_id IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID_FULL
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_FULL
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

    
  	CURSOR budget_category IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_FULL
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_FULL;  

--
-- CCN13700 start
--
	     
  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id_full
       AND scheme_version = :parameter.p2_scheme_version_full;
     
  vd_date_of_estimate DATE; 
  v2_quantity NUMBER(3);
  
  CURSOR get_quantity IS
  SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
AND trunc(vd_date_of_estimate) BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate)); 	     
	     
	     

    CURSOR new_costs IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_full
   AND sbfm.scheme_version = :parameter.p2_scheme_version_full
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_full
   AND sbfm.scheme_version = :parameter.p2_scheme_version_full
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_full
   AND sbfm.scheme_version = :parameter.p2_scheme_version_full
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_full
and sbfm.scheme_version = :parameter.p2_scheme_version_full
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_full
and sbfm.scheme_version = :parameter.p2_scheme_version_full
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  vn_past_code_amount   	NUMBER;
       
  CURSOR terms_recovered_asset IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.P2_SCHEME_ID_full
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_full
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;    

  CURSOR get_fees Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.P2_SCHEME_ID_full
and sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_full
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

--CCN10061 Start bc/vat rate changes full

  vn_budget_code	     varchar2(3);
  vn_cost_per_bc       number;
  vn_cost_per_customer number;
  vn_total_customers   number;
  vn_cost_per_vat_rate number;
  vn_total_cost_vat    number;
  vn_terms_split_id		 number;
  vn_pre_vat_text      VARCHAR2(250);
  vn_vat_total_text    VARCHAR2(250);
  vn_pre_vat_text_final      VARCHAR2(500);
  vn_vat_total_text_final    VARCHAR2(500);
  vn_vat_total_cost    number;
    vn_loop_counter NUMBER;

--
--CCN13700 start
--

      
CURSOR get_vat_total_amount IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id_full
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_full
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_full
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_full
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_full
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_full
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
AND bc.budget_code = vn_budget_code
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_full
and sbfm.scheme_version = :parameter.p2_scheme_version_full
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
AND bc.budget_code = vn_budget_code
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_full
and sbfm.scheme_version = :parameter.p2_scheme_version_full
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_full
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_full
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id_full
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_full
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1,vn_expenditure_type2)
       AND BC.BUDGET_CODE = vn_budget_code
       AND 1 = vn_loop_counter
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;



  CURSOR get_budget_code IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id_full
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_full
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

  vn_cust_per_vat_rate NUMBER;

  CURSOR user_applied_terms_vat IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id)));
     
--CCN06164 End bc/vat rate changes full

--
-- dual offer cursors
-- 

    vn_new_cont_dual NUMBER;
    vn_new_fees_dual NUMBER;
    vn_new_non_cont_dual NUMBER;
    vn_total_cost_dual NUMBER;
    vn_reg_payment_dual NUMBER;
    vn_total_charge_dual NUMBER; 
    vn_vat_rate_dual number;
 --   vn_terms_split_id_dual		 number;     
    
      CURSOR terms_split_id_dual IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;    
    

  	CURSOR budget_category_dual IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;  

  CURSOR get_fees_dual Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

    CURSOR new_costs_dual IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
    select 2, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
 from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid;

  vn_past_code_amount_dual   	NUMBER;     
  CURSOR terms_recovered_asset_dual IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.p2_scheme_version_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID; 
       
--CCN10061 Start bc/vat rate changes dual

  vn_budget_code_dual	     varchar2(3);
  vn_cost_per_bc_dual       number;
  vn_cost_per_customer_dual number;
  vn_total_customers_dual   number;
  vn_cost_per_vat_rate_dual number;
  vn_total_cost_vat_dual    number;
  vn_terms_split_id_dual		 number;
  vn_pre_vat_text_dual      VARCHAR2(250);
  vn_vat_total_text_dual    VARCHAR2(250);
  vn_pre_vat_text_final_dual      VARCHAR2(500);
  vn_vat_total_text_final_dual    VARCHAR2(500);
  vn_vat_total_cost_dual    number;
      
CURSOR get_vat_total_amount_dual IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code_dual
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
    select 2, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
 from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
and SBFM.BUDGET_CODE = BC.BUDGET_CODE
AND bc.budget_code = vn_budget_code_dual
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code_dual
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
       AND BC.BUDGET_CODE = vn_budget_code_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code_dual IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id_dual
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

  vn_cust_per_vat_rate_dual NUMBER;

  CURSOR user_applied_terms_vat_dual IS
   select uatgs.QUANTITY, ri.NUMBER_FIELD1 
     from USER_APPL_TERMS_GEN_STAN uatgs, 
          CROWN_OWNER.REFERENCE_ITEM ri
    where ri.REFERENCE_ITEM_ID = uatgs.VAT_TYPE_RI
      and uatgs.TERMS_SPLIT_ID = vn_terms_split_id_dual;
         
     
--CCN10061 End bc/vat rate changes dual


BEGIN



--
-- Populate table with costs for main scheme
--

    OPEN terms_split_id;
    FETCH terms_split_id
    INTO vn_terms_split_id;
    CLOSE terms_split_id;

	OPEN budget_category;
	FETCH budget_category
	INTO v2_budget_cat_ind;
	CLOSE budget_category;
	

	
  IF v2_budget_cat_ind IN ('E','N')  THEN
    vn_expenditure_type1 := 226;
    vn_expenditure_type2 := 227;
  ELSE
    vn_expenditure_type1 := 258;
  END IF;  


  IF vn_expenditure_type1 = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_full,:PARAMETER.P2_SCHEME_VERSION_FULL,user_pk.get_userid,vn_expenditure_type1);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_full,:PARAMETER.P2_SCHEME_VERSION_FULL,user_pk.get_userid);    
  END IF;
 -- commit;


--
-- get fees
--
    vn_new_cont :=0;
    vn_new_fees :=0;
    vn_new_non_cont :=0;
    vn_total_cost :=0;
    vn_reg_payment :=0;
    vn_total_charge := 0;
  for get_rec IN get_fees LOOP
    vn_new_fees := vn_new_fees+get_rec.fees;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_1 := vn_new_fees;

--
-- CCN13700 start
--

  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
  
  OPEN get_quantity;
  FETCH get_quantity
  INTO v2_quantity;
  CLOSE get_quantity;

--
-- CCN13700 END
--

  
--
-- get non-contestable costs
--
  for get_rec IN new_costs LOOP
  	vn_new_cont := vn_new_cont+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont := vn_new_non_cont+get_rec.NONCONTESTABLE_COST;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_1 := vn_new_non_cont;
--
-- get contestable costs
--
 :TERMS_CONNECTION_LETTERS_SBK.CONTESTABLE_WORKS_1 := vn_new_cont;
--
-- get ECCR payment
--
  OPEN terms_recovered_asset;
	FETCH terms_recovered_asset
  INTO vn_reg_payment;
	CLOSE terms_recovered_asset;
	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_1 := vn_reg_payment;
	
-- 
-- get connection charge ex vat
--
  vn_total_charge := NVL(vn_new_cont,0)+NVL(vn_new_non_cont,0)+NVL(vn_new_fees,0)+NVL(vn_reg_payment,0);

	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_1 := vn_total_charge;
  
--
-- get vat amount
--

--
-- CCN10061 start bc/vat split full
--
--  delete from conn_letter_budget_vat
--  where scheme_id = :parameter.p2_scheme_id_full
--   and scheme_version = :parameter.P2_SCHEME_VERSION_full;
--  commit;

--open cursor to get number of budget codes and loop round for each one
--	vn_vat_total_cost := 0;
--	vn_total_cost_vat := 0;
--	vn_loop_counter := 1;


--	vn_total_customers :=0;
--  FOR get_rec IN get_budget_code LOOP
--  	vn_cost_per_bc := 0;
-- 	vn_budget_code := NULL;
--  	vn_total_customers := NULL;
--  	vn_terms_split_id := NULL;
  	
--  	vn_budget_code := get_rec.budget_code;
--    vn_total_customers := get_rec.number_of_connections;
--    vn_terms_split_id := get_rec.terms_split_id;

--open cursor to get vat_total_amount

--    OPEN get_vat_total_amount;
--    FETCH get_vat_total_amount
--    INTO vn_cost_per_bc;
--    CLOSE get_vat_total_amount;
    
--if cost is greater then 0 carry on
--    IF vn_cost_per_bc >0 THEN
    	
--use number of connections to divide the vn_total_amount into vn_cost_per_customer    	
--      vn_cost_per_customer := round(vn_cost_per_bc/vn_total_customers,2);
--open cursor user_applied_terms_vat to get vat_rate and number of quantity at vat rate and loop      
      FOR get_rec IN user_applied_terms_vat LOOP
 --     	vn_total_customers := NULL;
      	vn_vat_rate := NULL;     	
      --  vn_cust_per_vat_rate := NULL;	     	
      	
      --     	vn_total_customers := get_rec.customers;
           	vn_vat_rate := get_rec.quantity;
     --multiply the number of connections with vn_cost_per_customer into vn_cust_per_vat_rate      	
--           	vn_cost_per_vat_rate := round(vn_cost_per_customer*vn_total_customers,2);
      	--multiply vn_cost_per_vat_rate with vat rate to get vn_total_cost_vat rate
--        vn_total_cost_vat := round(vn_vat_rate*vn_cost_per_vat_rate,2)/100;
--if more then one vat rate concat vn_total
--	      insert into conn_letter_budget_vat(scheme_id,scheme_version,budget_code,vat_rate,total_cost,vat_total_cost)
--	      values(:parameter.p2_scheme_id_full,:parameter.P2_SCHEME_VERSION_full,vn_budget_code,vn_vat_rate,vn_cost_per_vat_rate,vn_total_cost_vat);
--	      commit;
--	      vn_loop_counter := vn_loop_counter+1;

--	      vn_vat_total_cost := vn_vat_total_cost+vn_total_cost_vat;

      END LOOP;
--    END IF;
--  END LOOP;

  :TERMS_CONNECTION_LETTERS_SBK.VAT_1 := round(vn_vat_rate*nvl(vn_total_charge,0),2)/100;

--	    Set_Alert_Property('stop_ok',ALERT_MESSAGE_TEXT,'vn_vat_rate '||vn_vat_rate);
--	    vn_alert := Show_Alert('stop_ok');
	    
--	    Set_Alert_Property('stop_ok',ALERT_MESSAGE_TEXT,'vn_total_charge '||vn_total_charge);
--	    vn_alert := Show_Alert('stop_ok');	    


--
-- CCN10061 end bc/vat split full
-- 


--
-- get connection charge inc vat
--
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_1 := round(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_1,0)+vn_total_charge,2);

/*


--
-- Populate table with costs for dual offer
--

    OPEN terms_split_id_dual;
    FETCH terms_split_id_dual
    INTO vn_terms_split_id_dual;
    CLOSE terms_split_id_dual;

	OPEN budget_category_dual;
	FETCH budget_category_dual
	INTO v2_budget_cat_ind_dual;
	CLOSE budget_category_dual;
	

	
  IF v2_budget_cat_ind_dual IN ('E','N')  THEN
    vn_expenditure_type1_dual := 226;
    vn_expenditure_type2_dual := 227;
  ELSE
    vn_expenditure_type1_dual := 258;
  END IF;  


  IF vn_expenditure_type1_dual = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid,vn_expenditure_type1_dual);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid);    
  END IF;
 -- commit;
  

--
-- get fees
--
    vn_new_cont_dual :=0;
    vn_new_fees_dual :=0;
    vn_new_non_cont_dual :=0;
    vn_total_cost_dual :=0;
    vn_reg_payment_dual :=0;
    vn_total_charge_dual := 0;
    
  for get_rec IN get_fees_dual LOOP
    vn_new_fees_dual := vn_new_fees_dual+get_rec.fees;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_2 := vn_new_fees_dual;
  
--
-- get non-contestable costs
--
  for get_rec IN new_costs_dual LOOP
  	vn_new_cont_dual := vn_new_cont_dual+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont_dual := vn_new_non_conT_dual+get_rec.NONCONTESTABLE_COST;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_2 := vn_new_non_cont_dual;
--
-- get ECCR payment
--
  OPEN terms_recovered_asset_dual;
	FETCH terms_recovered_asset_dual
  INTO vn_reg_payment_dual;
	CLOSE terms_recovered_asset_dual;
	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_2 := vn_reg_payment_dual;
	
-- 
-- get connection charge ex vat
--
  vn_total_charge_dual := NVL(vn_new_cont_dual,0)+NVL(vn_new_non_cont_dual,0)+NVL(vn_new_fees_dual,0)+NVL(vn_reg_payment_dual,0);

	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_2 := vn_total_charge_dual;
  
--
-- get vat amount
--

--
-- CCN10061 start bc/vat split daul
--

  delete from conn_letter_budget_vat
  where scheme_id = :PARAMETER.P2_SCHEME_ID_dual
    and scheme_version = :PARAMETER.P2_SCHEME_VERSION_dual;
  commit;


--open cursor to get number of budget codes and loop round for each one
	vn_vat_total_cost_dual := 0;
	vn_total_cost_vat_dual := 0;
--	vn_pre_vat_text_final := NULL;
--	vn_vat_total_text_final := NULL;

	vn_total_customers :=0;
  FOR get_rec IN get_budget_code_dual LOOP
  	vn_cost_per_bc_dual := 0;
  	vn_budget_code_dual := NULL;
  	vn_total_customers_dual := NULL;
  	vn_terms_split_id_dual := NULL;
  	
  	vn_budget_code_dual := get_rec.budget_code;
    vn_total_customers_dual := get_rec.number_of_connections;
    vn_terms_split_id_dual := get_rec.terms_split_id;

--open cursor to get vat_total_amount

    OPEN get_vat_total_amount_dual;
    FETCH get_vat_total_amount_dual
    INTO vn_cost_per_bc_dual;
    CLOSE get_vat_total_amount_dual;
    
--if cost is greater then 0 carry on
    IF vn_cost_per_bc_dual >0 THEN
    	
--use number of connections to divide the vn_total_amount into vn_cost_per_customer    	
      vn_cost_per_customer_dual := round(vn_cost_per_bc_dual/vn_total_customers_dual,2);
--open cursor user_applied_terms_vat to get vat_rate and number of quantity at vat rate and loop      
      FOR get_rec IN user_applied_terms_vat_dual LOOP
 --     	vn_total_customers := NULL;
      	vn_vat_rate_dual := NULL;     	
      	
 --     	vn_total_customers := get_rec.customers;
      	vn_vat_rate_dual := get_rec.quantity;
--multiply the number of connections with vn_cost_per_customer into vn_cust_per_vat_rate      	
      	vn_cost_per_vat_rate_dual := round(vn_cost_per_customer_dual*vn_total_customers_dual,2);
      	--multiply vn_cost_per_vat_rate with vat rate to get vn_total_cost_vat rate
        vn_total_cost_vat_dual := round(vn_vat_rate_dual*vn_cost_per_vat_rate_dual,2)/100;
--if more then one vat rate concat vn_total

	    Set_Alert_Property('stop_ok',ALERT_MESSAGE_TEXT,'1 vat '||vn_vat_total_cost_dual);
	    vn_alert := Show_Alert('stop_ok');
	    
	      insert into conn_letter_budget_vat(scheme_id,scheme_version,budget_code,vat_rate,total_cost,vat_total_cost)
	      values(:parameter.p2_scheme_id_dual,:parameter.P2_SCHEME_VERSION_dual,vn_budget_code_dual,vn_vat_rate_dual,vn_cost_per_vat_rate_dual,vn_total_cost_vat_dual);
	      commit;

	      vn_vat_total_cost_dual := vn_vat_total_cost_dual+vn_total_cost_vat_dual;
      
      END LOOP;
    END IF;
  END LOOP;

      :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := vn_vat_total_cost_dual;
		
	    Set_Alert_Property('stop_ok',ALERT_MESSAGE_TEXT,'5 vat '||:TERMS_CONNECTION_LETTERS_SBK.VAT_2);
	    vn_alert := Show_Alert('stop_ok');

--
-- CCN10061 end bc/vat split dual
--  


--
-- get connection charge inc vat
--
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_2 := round(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_2,0)+vn_total_charge_dual,2);

*/
  commit;
		go_block('TERMS_CONNECTION_LETTERS_SBK');
		execute_query;

END;

--- rt_demand_letter\rdl_new_generate_costs.pl ---
PROCEDURE generate_costs IS
		
  
  vn_expenditure_type1        NUMBER;
  vn_expenditure_type2        NUMBER;
  v2_budget_cat_ind		        terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  vn_new_cont                 NUMBER;
  vn_new_non_cont             NUMBER;
  vn_total_cost               NUMBER;
  vn_reg_payment              NUMBER;
  vn_total_charge             NUMBER;
  vn_new_fees                 NUMBER;
  vn_vat_rate				          NUMBER;
  vd_date_of_estimate         DATE;
  vn_budget_code	            VARCHAR2(3);
  vn_cost_per_bc              NUMBER;
  vn_cost_per_customer        NUMBER;
  vn_total_customers          NUMBER;
  vn_cost_per_vat_rate        NUMBER;
  vn_total_cost_vat           NUMBER;
  vn_terms_split_id		        NUMBER;  
  vn_vat_total_cost           NUMBER;
  vn_loop_counter             NUMBER;
  vn_cust_per_vat_rate        NUMBER;
  vn_a_d_fee                  NUMBER;
  vn_a_d_fee_vat_total        NUMBER;
  vn_a_d_fee_inc_vat          NUMBER;
  vn_ad_vat_rate              NUMBER;
  v2_dno                      VARCHAR2(50);

  -- get main costs cursors
  CURSOR terms_split_id IS
    SELECT ts.terms_split_id
      FROM terms_budget_code_for_cat bcfc,
           terms_split ts
     WHERE ts.scheme_id = :parameter.p2_scheme_id
       AND ts.scheme_version = :parameter.p2_scheme_version
       AND ts.terms_budget_cat_id = bcfc.terms_budget_cat_id;

  CURSOR budget_category IS
	  SELECT budget_category_type_ind
	    FROM terms_budget_cat_for_scheme
	   WHERE scheme_id = :parameter.p2_scheme_id
	     AND scheme_version = :parameter.p2_scheme_version;

  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id
       AND scheme_version = :parameter.p2_scheme_version;

  CURSOR new_costs IS
    SELECT  DISTINCT 
              1,
              NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
              NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST,
              NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
              NVL(swe.description_for_customer,ci.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,bc.budget_code
       FROM scheme_breakdown_for_margins sbfm,
            cost_item ci,
            cost_item_element cie,
            cost_item_element	non_cont,
            cost_item_element	cont,
            work_category_for_scheme wcfs,
            standard_work_element swe,
            work_category wc,
            work_category_association wca,
            budget_code_for_scheme_split bcfss,
            budget_code bc,
           (SELECT rsi1.contingency_ind "CONTINGENCY_IND", rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version
              FROM terms_split ts1, recharge_statement_info rsi1
             WHERE ts1.terms_split_id = rsi1.terms_split_id
               AND rsi1.contingency_ind = 'Y') ts
      WHERE sbfm.scheme_id = :parameter.p2_scheme_id
        AND sbfm.scheme_version = :parameter.p2_scheme_version
        AND sbfm.userid = user_pk.get_userid
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND ci.cost_item_id = sbfm.cost_item_id
        AND ci.cost_item_indicator != 'T'
        AND cie.cost_item_id = ci.cost_item_id
        AND cie.budget_code IS NULL
        AND swe.standard_work_element_id(+) = ci.standard_work_element_id
        AND bcfss.scheme_id = sbfm.scheme_id
        AND bcfss.scheme_version = sbfm.scheme_version
        AND bc.budget_code = bcfss.budget_code
        AND bc.date_from = bcfss.budget_code_date_from
        AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
        AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND non_cont.cost_item_id(+) = sbfm.cost_item_id
        AND non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = sbfm.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
        AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
      UNION
     SELECT DISTINCT 
              1,
              NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
              NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
              NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
              NVL(swe.description_for_customer,ci.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,NULL
       FROM scheme_breakdown_for_margins sbfm,
            cost_item ci,
            work_category_for_scheme wcfs,
            cost_item_element non_cont,
            cost_item_element cont,
            standard_work_element swe,
            work_category_association wca,
            work_category wc,
            cost_item_allocation$v cia,
           (SELECT rsi1.contingency_ind "CONTINGENCY_IND", rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version
              FROM terms_split ts1, recharge_statement_info rsi1
             WHERE ts1.terms_split_id = rsi1.terms_split_id
               AND rsi1.contingency_ind = 'Y') ts
      WHERE sbfm.scheme_id = :parameter.p2_scheme_id
        AND sbfm.scheme_version = :parameter.p2_scheme_version
        AND sbfm.userid = user_pk.get_userid
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND ci.cost_item_id = sbfm.cost_item_id
        AND ci.cost_item_indicator != 'T'
        AND cia.cost_item_id = ci.cost_item_id
        AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
        AND cia.split_indicator = 0
        AND swe.standard_work_element_id(+) = ci.standard_work_element_id
        AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND non_cont.cost_item_id(+) = ci.cost_item_id
        AND non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = ci.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
      UNION
     SELECT DISTINCT 
              1,
              NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
              NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
              NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
              NVL(swe.description_for_customer,cip.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,
              null
       FROM scheme_breakdown_for_margins sbfm,
            cost_item ci,
            work_category_for_scheme wcfs,
            cost_item_element non_cont,
            cost_item_element cont,
            standard_work_element swe,
            work_category_association wca,
            work_category wc,
            cost_item_allocation$v cia,
            cost_item cip,
           (SELECT rsi1.contingency_ind "CONTINGENCY_IND", rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version
              FROM terms_split ts1, recharge_statement_info rsi1
             WHERE ts1.terms_split_id = rsi1.terms_split_id
               AND rsi1.contingency_ind = 'Y') ts
      WHERE sbfm.scheme_id = :parameter.p2_scheme_id
        AND sbfm.scheme_version = :parameter.p2_scheme_version
        AND sbfm.userid = user_pk.get_userid 
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND cip.cost_item_id = sbfm.cost_item_id
        AND cip.cost_item_indicator != 'T'
        AND ci.parent_cost_item_id = cip.cost_item_id
        AND cia.cost_item_id = ci.cost_item_id
        AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
        AND cia.split_indicator = 0
        AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
        AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND non_cont.cost_item_id(+) = sbfm.cost_item_id
        AND non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = sbfm.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
      UNION
     SELECT 2,
            SUM(CONTESTABLE_COST), 
            SUM(NONCONTESTABLE_COST), 
            work_cat_desc,  
            total_quantity, 
            'Travel', 
            budget_code, 
            work_cat_for_scheme_id, 
            null 
      FROM (SELECT  DISTINCT 
                      2,
                      DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                      DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.noncont_travel_cost,2),ROUND(sbfm.noncont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                      NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                      0 total_quantity,
                      'Travel',
                      bc.budget_code,
                      wcfs.work_cat_for_scheme_id,null
               FROM travel_cost_for_margins sbfm,
                    work_category_for_scheme wcfs,
                    work_category_association wca,
                    budget_code bc,
                    work_category wc,
                    cost_item ci,
                   (SELECT rsi1.contingency_ind "CONTINGENCY_IND", rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version
                      FROM terms_split ts1, recharge_statement_info rsi1
                     WHERE ts1.terms_split_id = rsi1.terms_split_id
                       AND rsi1.contingency_ind = 'Y') ts
              WHERE wc.work_category(+) = wcfs.work_category_2
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND ci.scheme_id = sbfm.scheme_id
                AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                AND ci.COST_ITEM_INDICATOR = 'T'
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                AND sbfm.scheme_id = wcfs.scheme_id
                AND sbfm.scheme_version = wcfs.scheme_version
                AND sbfm.scheme_id = :parameter.p2_scheme_id
                AND sbfm.scheme_version = :parameter.p2_scheme_version
                AND sbfm.userid = user_pk.get_userid
              UNION
             SELECT DISTINCT 2,
                      ROUND(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
                      0 NONCONTESTABLE_COST,
                      NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                      0 total_quantity,
                      'Travel',
                      bc.budget_code,
                      wcfs.work_cat_for_scheme_id,null
               FROM travel_cost_for_margins sbfm,
                    work_category_for_scheme wcfs,
                    work_category_association wca,
                    BUDGET_CODE BC,
                    work_category wc,
                    cost_item ci,
                    scheme_version sv,
                    budget_code_margin_applicable bcma,
                   (SELECT rsi1.contingency_ind "CONTINGENCY_IND", rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version
                      FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                     WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE wc.work_category(+) = wcfs.work_category_2
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost > 0)
                AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND ci.scheme_id = sbfm.scheme_id
                AND ci.scheme_version = sbfm.scheme_version
                AND ci.cost_item_indicator = 'T'
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.scheme_version
                AND sbfm.budget_code = bc.budget_code
                AND sbfm.budget_code = bcma.budget_code
                AND sbfm.engineering_classification = bcma.engineering_classification
                AND bcma.dno = v2_dno
                AND sbfm.budget_code_date_from = bc.date_from            
                AND sbfm.budget_code_date_from = bcma.budget_code_date_from                
                AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
                AND sv.scheme_id = sbfm.scheme_id
                AND sv.scheme_version = sbfm.scheme_version
                AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                AND sbfm.scheme_id = wcfs.scheme_id
                AND sbfm.scheme_version = wcfs.scheme_version
                AND sbfm.scheme_id = :parameter.p2_scheme_id
                AND sbfm.scheme_version = :parameter.p2_scheme_version
                AND sbfm.userid = user_pk.get_userid)
              GROUP BY work_cat_desc, total_quantity, 'Travel', budget_code, work_cat_for_scheme_id;

  CURSOR terms_recovered_asset IS
    SELECT distinct (NVL(potential_refund,0)+NVL(past_codes_amount,0))-NVL(comm_credit_value,0)
      FROM terms_split ts,
           budget_code bc,
           terms_budget_code_for_cat tbcfc,
           terms_budget_cat_for_scheme tbcfs
     WHERE tbcfs.scheme_id = :parameter.p2_scheme_id
       AND tbcfs.scheme_version = :parameter.p2_scheme_version
       AND tbcfs.terms_budget_cat_id=tbcfc.terms_budget_cat_id
       AND tbcfc.budget_code=bc.budget_code
       AND tbcfc.budget_code_date_from=bc.date_from
       AND bc.type_of_expenditure_ri =258
       AND tbcfs.terms_budget_cat_id=ts.terms_budget_cat_id;

  CURSOR get_fees Is
    SELECT SUM(ROUND(sbfm.fees_cost)) FEES
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           work_category wc,
           historic_swe hs
     WHERE sbfm.cost_item_id = ci.cost_item_id
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       AND wcfs.work_category_2(+) = wc.work_category
       AND sbfm.fees_cost > 0
       AND sbfm.description = 'FEES'
       AND sbfm.standard_work_element_id = hs.standard_work_element_id
       AND hs.date_to is null
       AND sbfm.scheme_id = wcfs.scheme_id
       AND sbfm.scheme_version = wcfs.scheme_version
       AND sbfm.scheme_id = :parameter.P2_SCHEME_ID
       AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
       AND sbfm.userid = user_pk.get_userid
     GROUP BY wc.work_category, wc.description_for_customer;

  CURSOR get_vat_total_amount IS
    select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
     FROM (SELECT DISTINCT 
                    1,
                    NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
                    NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST,
                    NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
                    NVL(swe.description_for_customer,ci.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
             FROM scheme_breakdown_for_margins sbfm,
                  cost_item ci,
                  cost_item_element cie,
                  cost_item_element	non_cont,
                  cost_item_element	cont,
                  work_category_for_scheme wcfs,
                  standard_work_element swe,
                  work_category wc,
                  work_category_association wca,
                  budget_code_for_scheme_split bcfss,
                  budget_code bc,
                 (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                    FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                   WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     AND rsi1.CONTINGENCY_IND = 'Y') ts
            where SBFM.SCHEME_ID = :parameter.p2_scheme_id
              AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
              AND sbfm.userid = user_pk.get_userid
              AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
              AND ts.scheme_id(+) = sbfm.scheme_id
              AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
              AND ci.cost_item_id = sbfm.cost_item_id
              AND ci.cost_item_indicator != 'T'
              AND cie.cost_item_id = ci.cost_item_id
              AND cie.budget_code IS NULL
              AND swe.standard_work_element_id(+) = ci.standard_work_element_id
              AND bcfss.scheme_id = sbfm.scheme_id
              AND bcfss.scheme_version = sbfm.scheme_version
              AND BC.BUDGET_CODE = BCFSS.BUDGET_CODE
              AND bcfss.budget_code = vn_budget_code
              AND bc.date_from = bcfss.budget_code_date_from
              AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
              AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
              AND wc.work_category = wcfs.work_category_1
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND non_cont.cost_item_id(+) = sbfm.cost_item_id
              AND non_cont.type_of_cost_ri(+) = 206
              AND cont.cost_item_id(+) = sbfm.cost_item_id
              AND cont.type_of_cost_ri(+) = 207
              AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
            UNION
           SELECT DISTINCT 
                    1,
                    NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                    NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                    NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                    NVL(swe.description_for_customer,ci.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
             FROM scheme_breakdown_for_margins sbfm,
                  cost_item ci,
                  work_category_for_scheme wcfs,
                  cost_item_element cie,
                  cost_item_element non_cont,
                  cost_item_element cont,
                  standard_work_element swe,
                  work_category_association wca,
                  work_category wc,
                  cost_item_allocation$v cia,
                 (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                    from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                   where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     and rsi1.CONTINGENCY_IND = 'Y') ts
            WHERE sbfm.scheme_id = :parameter.p2_scheme_id
              AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
              AND sbfm.userid = user_pk.get_userid
              AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
              AND ts.scheme_id(+) = sbfm.scheme_id
              AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
              AND ci.cost_item_id = sbfm.cost_item_id
              AND ci.cost_item_indicator != 'T'
              AND CIA.COST_ITEM_ID = CI.COST_ITEM_ID
              AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
              AND cie.budget_code = vn_budget_code
              AND cia.cost_item_id = ci.cost_item_id
              AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
              AND cia.split_indicator = 0
              AND swe.standard_work_element_id(+) = ci.standard_work_element_id
              AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
              AND wc.work_category = wcfs.work_category_1
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND non_cont.cost_item_id(+) = ci.cost_item_id
              AND non_cont.type_of_cost_ri(+) = 206
              AND cont.cost_item_id(+) = ci.cost_item_id
              AND cont.type_of_cost_ri(+) = 207
            UNION
           SELECT DISTINCT 
                    1,
                    NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                    NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                    NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                    NVL(swe.description_for_customer,cip.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
               FROM scheme_breakdown_for_margins sbfm,
                    cost_item ci,
                    work_category_for_scheme wcfs,
                    cost_item_element cie,
                    cost_item_element non_cont,
                    cost_item_element cont,
                    standard_work_element swe,
                    work_category_association wca,
                    work_category wc,
                    cost_item_allocation$v cia,
                    cost_item cip,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                      FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                     WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE sbfm.scheme_id = :parameter.p2_scheme_id
                AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
                AND sbfm.userid = user_pk.get_userid
                AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                AND cip.cost_item_id = sbfm.cost_item_id
                AND cip.cost_item_indicator != 'T'
                AND ci.parent_cost_item_id = cip.cost_item_id
                AND CIA.COST_ITEM_ID = CI.COST_ITEM_ID
                AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
                AND cie.budget_code = vn_budget_code
                AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                AND cia.split_indicator = 0
                AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
                AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND wc.work_category = wcfs.work_category_1
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND non_cont.cost_item_id(+) = sbfm.cost_item_id
                AND non_cont.type_of_cost_ri(+) = 206
                AND cont.cost_item_id(+) = sbfm.cost_item_id
                AND cont.type_of_cost_ri(+) = 207
              UNION
             select 2,
                    SUM(CONTESTABLE_COST), 
                    SUM(NONCONTESTABLE_COST),
                    work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
                   (SELECT  DISTINCT 
                              2,
                              DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                              DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.noncont_travel_cost,2),ROUND(sbfm.noncont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                              NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code,
                              wcfs.work_cat_for_scheme_id
                       from travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            budget_code bc,
                            work_category wc,
                            cost_item ci,
                           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                             WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                               AND rsi1.CONTINGENCY_IND = 'Y') ts
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        and wca.work_category_1(+) = wcfs.work_category_1
                        and wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        and ci.scheme_id = sbfm.scheme_id
                        and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                        and ci.COST_ITEM_INDICATOR = 'T'
                        and bc.budget_code = vn_budget_code
                        and ts.scheme_id(+) = sbfm.scheme_id
                        and ts.scheme_version(+) = sbfm.SCHEME_VERSION
                        AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                        ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                        and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        and sbfm.scheme_id = wcfs.scheme_id
                        and sbfm.scheme_version = wcfs.scheme_version
                        and sbfm.scheme_id = :parameter.p2_scheme_id
                        and sbfm.scheme_version = :parameter.p2_scheme_version
                        and sbfm.userid = user_pk.get_userid
                      UNION
                     SELECT DISTINCT 
                              2,
                              ROUND(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
                              0 NONCONTESTABLE_COST,
                              NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code,
                              wcfs.work_cat_for_scheme_id
                       FROM travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            budget_code bc,
                            work_category wc,
                            cost_item ci,
                            scheme_version sv,
                            budget_code_margin_applicable bcma,
                           (SELECT rsi1.contingency_ind "CONTINGENCY_IND" ,rsi1.contingency_amount "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                              FROM terms_split ts1, recharge_statement_info rsi1
                             WHERE ts1.terms_split_id = rsi1.terms_split_id
                               AND rsi1.contingency_ind = 'Y') ts
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        AND wca.work_category_1(+) = wcfs.work_category_1
                        AND wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        AND ci.scheme_id = sbfm.scheme_id
                        AND ci.scheme_version = sbfm.scheme_version
                        AND ci.cost_item_indicator = 'T'
                        AND bc.budget_code = vn_budget_code
                        AND ts.scheme_id(+) = sbfm.scheme_id
                        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                        AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                        AND sbfm.budget_code = bcma.budget_code
                        AND sbfm.engineering_classification = bcma.engineering_classification
                        AND bcma.dno = v2_dno
                        AND sbfm.budget_code_date_from = bc.date_from            
                        AND sbfm.budget_code_date_from = bcma.budget_code_date_from                
                        AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
                        AND sv.scheme_id = sbfm.scheme_id
                        AND sv.scheme_version = sbfm.scheme_version
                        AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                        AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND sbfm.scheme_version = wcfs.scheme_version
                        AND sbfm.scheme_id = :parameter.p2_scheme_id
                        AND sbfm.scheme_version = :parameter.p2_scheme_version
                        AND sbfm.userid = user_pk.get_userid)
                      GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
                      UNION
                     SELECT 2,
                            SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
                            0 NONCONTESTABLE_COST,
                            '0' work_cat_desc,
                            0 total_quantity,
                            'Fees',
                            'Fees', 
                            wcfs.work_cat_for_scheme_id
                       FROM scheme_breakdown_for_margins sbfm,
                            cost_item ci,
                            cost_item_element cie,
                            work_category_for_scheme wcfs,
                            work_category wc,
                            historic_swe hs
                      WHERE sbfm.cost_item_id = ci.cost_item_id
                        AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND wcfs.work_category_2(+) = wc.work_category
                        AND sbfm.fees_cost > 0
                        AND SBFM.DESCRIPTION = 'FEES'
                        AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
                        AND cie.budget_code = vn_budget_code
                        AND sbfm.standard_work_element_id = hs.standard_work_element_id
                        AND hs.date_to is null
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
                        AND SBFM.SCHEME_ID = :parameter.p2_scheme_id
                        AND SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
                        AND sbfm.userid = user_pk.get_userid
                      GROUP BY WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
                      UNION
                     SELECT DISTINCT 
                              2, 
                              (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
                              0 NONCONTESTABLE_COST,
                              '0' work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
                       FROM TERMS_SPLIT TS,
                            BUDGET_CODE BC,
                            TERMS_BUDGET_CODE_FOR_CAT TBCFC,
                            TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
                      WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id
                        AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
                        AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
                        AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
                        AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
                        AND BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1,vn_expenditure_type2)
                        AND BC.BUDGET_CODE = vn_budget_code
                        AND 1 = vn_loop_counter
                        AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
                      GROUP BY 1;

  CURSOR get_budget_code IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

  CURSOR user_applied_terms_vat IS
    select uatgs.quantity, ri.number_field1
      from user_appl_terms_gen_stan uatgs,
           crown_owner.reference_item ri
     where ri.reference_item_id = uatgs.vat_type_ri
       and uatgs.terms_split_id = vn_terms_split_id;

  CURSOR get_a_d_fee IS
    SELECT NVL(SUM(ROUND(DECODE(NVL(ts.contingency_ind,'N'),'N',sbfm.fees_cost,sbfm.fees_cost*NVL(ts.contingency_amount,0)/100+sbfm.fees_cost))),0) as "a_d"
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           work_category wc,
           historic_swe hs,
          (SELECT rsi1.contingency_ind "CONTINGENCY_IND" ,rsi1.contingency_amount "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
             FROM terms_split ts1, recharge_statement_info rsi1
            WHERE ts1.terms_split_id = rsi1.terms_split_id
              AND rsi1.contingency_ind = 'Y') ts
     WHERE sbfm.cost_item_id = ci.cost_item_id
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       AND wcfs.work_category_2(+) = wc.work_category
       AND sbfm.fees_cost > 0
       AND sbfm.description = 'FEES'
       AND wc.work_category like '%Design%'
       AND ts.scheme_id(+) = sbfm.scheme_id
       AND ts.scheme_version(+) = sbfm.scheme_version
       AND sbfm.standard_work_element_id = hs.standard_work_element_id
       AND hs.date_to IS NULL
       AND sbfm.scheme_id = wcfs.scheme_id
       AND sbfm.scheme_version = wcfs.scheme_version
       AND sbfm.userid = user_pk.get_userid
       AND sbfm.scheme_id = :parameter.p2_scheme_id
       AND sbfm.scheme_version = :parameter.p2_scheme_version;

    CURSOR get_vat_rate IS
      SELECT quantity
        FROM terms_general_standard
       WHERE terms_general_standard_id IN (SELECT t.terms_general_standard_id
                                             FROM terms_general_standard t
                                            WHERE t.terms_general_standard_id IN (SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                   WHERE t.terms_area_ri = 1339
                                                                                     AND t.date_from IS NOT NULL
                                                                                     AND t.date_to IS NULL
                                                                                     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
                                                                                     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id
                                                                                   UNION
                                                                                  SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                   WHERE t.terms_area_ri     = 1339
                                                                                     AND t.terms_standard_ri = 1337
                                                                                     AND t.date_from IS NOT NULL
                                                                                     AND t.date_to IS NULL
                                                                                     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
                                                                                     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id
                                                                                     AND NOT EXISTS (SELECT 1 
                                                                                                       FROM USER_APPL_TERMS_GEN_STAN 
                                                                                                      WHERE TERMS_SPLIT_ID = vn_terms_split_id)
                                                                                  )
                                          );

BEGIN

  v2_dno := crown_owner.util_scheme_procs.get_dno_for_scheme(:parameter.p2_scheme_id, :parameter.p2_scheme_version);

  OPEN terms_split_id;
  FETCH terms_split_id
  INTO vn_terms_split_id;
  CLOSE terms_split_id;

	OPEN budget_category;
	FETCH budget_category
	INTO v2_budget_cat_ind;
	CLOSE budget_category;

  IF v2_budget_cat_ind IN ('E','N')  THEN
    vn_expenditure_type1 := 226;
    vn_expenditure_type2 := 227;
  ELSE
    vn_expenditure_type1 := 258;
  END IF;

  MESSAGE('Calculating Costs 10%', NO_ACKNOWLEDGE);
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 10%';

  IF vn_expenditure_type1 = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:PARAMETER.P2_SCHEME_VERSION,user_pk.get_userid,vn_expenditure_type1);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:PARAMETER.P2_SCHEME_VERSION,user_pk.get_userid);
  END IF;
 
  synchronize;
  MESSAGE('Calculating Costs 20%',NO_ACKNOWLEDGE);
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 20%';

  vn_new_cont     := 0;
  vn_new_fees     := 0;
  vn_new_non_cont := 0;
  vn_total_cost   := 0;
  vn_reg_payment  := 0;
  vn_total_charge := 0;
  
  FOR get_rec IN get_fees LOOP
    vn_new_fees := vn_new_fees+get_rec.fees;
  END LOOP;

  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_1 := VN_NEW_FEES;

  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;

  -- get non-contestable costs  
  FOR get_rec IN new_costs LOOP
  	vn_new_cont := vn_new_cont+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont := vn_new_non_cont+get_rec.NONCONTESTABLE_COST;
  END LOOP;
  
  synchronize;
  message('Calculating Costs 30%',no_acknowledge);

  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 30%';
  :terms_connection_letters_sbk.non_cont_works_1 := vn_new_non_cont;

  -- get contestable costs
  synchronize;
  message('Calculating Costs 40%',no_acknowledge);
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 40%';

 :terms_connection_letters_sbk.contestable_works_1 := vn_new_cont;
  
  -- get ECCR payment
  OPEN terms_recovered_asset;
	FETCH terms_recovered_asset
  INTO vn_reg_payment;
	CLOSE terms_recovered_asset;

  synchronize;
  message('Calculating Costs 50%',no_acknowledge);
  
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 50%';
	:terms_connection_letters_sbk.reg_connect_charge_1 := vn_reg_payment;
  vn_total_charge := NVL(vn_new_cont,0)+NVL(vn_new_non_cont,0)+NVL(vn_new_fees,0)+NVL(vn_reg_payment,0);
  synchronize;
  message('Calculating Costs 60%',no_acknowledge);
  
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 60%';
	:terms_connection_letters_sbk.connection_charge_1 := vn_total_charge;
	synchronize;
  message('Calculating Costs 70%',no_acknowledge);
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 70%';

  DELETE 
    FROM conn_letter_budget_vat
   WHERE scheme_id = :parameter.p2_scheme_id
     AND scheme_version = :parameter.p2_scheme_version;
  COMMIT;

	vn_vat_total_cost   := 0;
	vn_total_cost_vat   := 0;
	vn_loop_counter     := 1;
	vn_total_customers  := 0;

  FOR get_rec IN get_budget_code LOOP
  	vn_cost_per_bc      := 0;
  	vn_budget_code      := NULL;
  	vn_total_customers  := NULL;
  	vn_terms_split_id   := NULL;
  	vn_budget_code      := get_rec.budget_code;
    vn_total_customers  := get_rec.number_of_connections;
    vn_terms_split_id   := get_rec.terms_split_id;

    OPEN get_vat_total_amount;
    FETCH get_vat_total_amount
    INTO vn_cost_per_bc;
    CLOSE get_vat_total_amount;

    -- If Cost Is Greater Then 0 Carry On
    IF vn_cost_per_bc >0 THEN
      --Use Number Of Connections To Divide The Vn_Total_Amount Into Vn_Cost_Per_Customer
      vn_cost_per_customer := ROUND(vn_cost_per_bc/vn_total_customers,2);
      -- Open Cursor User_Applied_Terms_Vat To Get Vat_Rate And Number Of Quantity At Vat Rate And Loop
      FOR get_rec IN user_applied_terms_vat LOOP
      	vn_vat_rate           := NULL;
        vn_cust_per_vat_rate  := NULL;
        vn_cust_per_vat_rate  := get_rec.quantity;
      	vn_vat_rate           := get_rec.number_field1;
        -- Multiply The Number Of Connections With Vn_Cost_Per_Customer Into Vn_Cust_Per_Vat_Rate
      	vn_cost_per_vat_rate := ROUND(vn_cost_per_customer*vn_cust_per_vat_rate,2);
      	-- Multiply Vn_Cost_Per_Vat_Rate With Vat Rate To Get Vn_Total_Cost_Vat Rate
        vn_total_cost_vat := ROUND(vn_vat_rate*vn_cost_per_vat_rate,2)/100;
        
        -- If More Then One Vat Rate Concat Vn_Total
	      IF vn_budget_code = 'RC' THEN
	      	vn_budget_code := 0;
        END IF;
        
        SYNCHRONIZE;
        message('Calculating Costs 80%',no_acknowledge);
        :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 80%';

	      insert into conn_letter_budget_vat(scheme_id,scheme_version,budget_code,vat_rate,total_cost,vat_total_cost)
	      values(:parameter.p2_scheme_id,:parameter.P2_SCHEME_VERSION,vn_budget_code,vn_vat_rate,vn_cost_per_vat_rate,vn_total_cost_vat);
	      commit;

	      vn_loop_counter := vn_loop_counter+1;
	      vn_vat_total_cost := vn_vat_total_cost+vn_total_cost_vat;

      END LOOP;
    END IF;
  END LOOP;
  SYNCHRONIZE;
  message('Calculating Costs 90%',no_acknowledge);
  :nbt_please_wait_sbk.di_progress:='Calculating Costs 90%';
  :terms_connection_letters_sbk.vat_1 := vn_vat_total_cost;

  -- get connection charge inc vat
	:terms_connection_letters_sbk.connect_charge_inc_1 := ROUND(NVL(:terms_connection_letters_sbk.vat_1, 0 ) + vn_total_charge, 2);

  OPEN get_vat_rate;
  FETCH get_vat_rate
  INTO vn_ad_vat_rate;
  CLOSE get_vat_rate;

  OPEN get_a_d_fee;
  FETCH get_a_d_fee
  INTO vn_a_d_fee;
  CLOSE get_a_d_fee;

  :terms_connection_letters_sbk.option_1_vat_rate := vn_ad_vat_rate;

  IF vn_a_d_fee >0 THEN
    vn_a_d_fee_vat_total := vn_a_d_fee * vn_ad_vat_rate / 100;
    vn_a_d_fee_inc_vat   := vn_a_d_fee + vn_a_d_fee_vat_total;
    :terms_connection_letters_sbk.assessment_design_fees_prevat := vn_a_d_fee;
    :terms_connection_letters_sbk.assessment_design_fees_vat    := vn_a_d_fee_vat_total;
    :terms_connection_letters_sbk.assessment_design_fees_total  := vn_a_d_fee_inc_vat;
  ELSE
    :terms_connection_letters_sbk.assessment_design_fees_prevat := 0;
    :terms_connection_letters_sbk.assessment_design_fees_vat    := 0;
    :terms_connection_letters_sbk.assessment_design_fees_total  := 0;
  END IF;

  SYNCHRONIZE;
  MESSAGE('Calculating Costs 100%',NO_ACKNOWLEDGE);
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 100%';
  COMMIT;

  GO_BLOCK('TERMS_CONNECTION_LETTERS_SBK');
	EXECUTE_QUERY;

END;

--- rt_demand_letter\rdl_new_generate_costs_dual.pl ---
PROCEDURE GENERATE_COSTS_DUAL IS

  v2_dno                          VARCHAR2(50);
  vn_expenditure_type1_dual       NUMBER;
  vn_expenditure_type2_dual       NUMBER;
  vn_vat_dual                     NUMBER;
  v2_budget_cat_ind_dual		      terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  vn_new_cont_dual                NUMBER;
  vn_new_fees_dual                NUMBER;
  vn_new_non_cont_dual            NUMBER;
  vn_total_cost_dual              NUMBER;
  vn_reg_payment_dual             NUMBER;
  vn_total_charge_dual            NUMBER; 
  vn_vat_rate_dual                NUMBER;
  vd_date_of_estimate             DATE; 
  vn_budget_code_dual	            VARCHAR2(3);
  vn_cost_per_bc_dual             NUMBER;
  vn_cost_per_customer_dual       NUMBER;
  vn_total_customers_dual         NUMBER;
  vn_cost_per_vat_rate_dual       NUMBER;
  vn_total_cost_vat_dual          NUMBER;
  vn_terms_split_id_dual		      NUMBER;
  vn_vat_total_cost_dual          NUMBER;
  vn_loop_counter	                NUMBER;
  vn_vat_rate_new_dual            NUMBER;
  vn_cust_per_vat_rate_dual       NUMBER;

  CURSOR terms_split_id_dual IS
    SELECT ts.terms_split_id 
      FROM terms_budget_code_for_cat bcfc,
           terms_split ts
     WHERE ts.scheme_id = :parameter.p2_scheme_id_dual
       AND ts.scheme_version = :parameter.p2_scheme_version_dual
       AND ts.terms_budget_cat_id = bcfc.terms_budget_cat_id;        

  CURSOR budget_category_dual IS
	  SELECT budget_category_type_ind
	    FROM terms_budget_cat_for_scheme
	   WHERE scheme_id = :parameter.p2_scheme_id_dual
	     AND scheme_version = :parameter.p2_scheme_version_dual;  

  CURSOR get_fees_dual Is
    SELECT sum(ROUND(sbfm.fees_cost)) FEES
      FROM scheme_breakdown_for_margins sbfm, 
           cost_item ci, 
           work_category_for_scheme wcfs,
           work_category wc,
           historic_swe hs
     WHERE sbfm.cost_item_id = ci.cost_item_id
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       AND wcfs.work_category_2(+) = wc.work_category
       AND sbfm.fees_cost > 0 
       AND sbfm.description = 'FEES'
       AND sbfm.standard_work_element_id = hs.standard_work_element_id
       AND hs.date_to is null
       AND sbfm.scheme_id = wcfs.scheme_id
       AND sbfm.scheme_version = wcfs.scheme_version
       AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
       AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
       AND sbfm.userid = user_pk.get_userid
     GROUP BY wc.work_category, wc.description_for_customer;

  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id_dual
       AND scheme_version = :parameter.p2_scheme_version_dual;
     
  CURSOR new_costs_dual IS
    SELECT  DISTINCT 
              1, 
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
              nvl(swe.description_for_customer,ci.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,bc.budget_code 
         FROM scheme_breakdown_for_margins sbfm,
              cost_item ci,
              cost_item_element cie,
              cost_item_element	non_cont,
              cost_item_element	cont,
              work_category_for_scheme wcfs,
              standard_work_element swe,
              work_category wc,
              work_category_association wca,
              budget_code_for_scheme_split bcfss,
              budget_code bc,
             (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
               WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                 AND rsi1.CONTINGENCY_IND = 'Y') ts
        WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
          AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
          AND sbfm.userid = user_pk.get_userid
          AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
          AND ts.scheme_id(+) = sbfm.scheme_id
          AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
          AND ci.cost_item_id = sbfm.cost_item_id
          AND ci.cost_item_indicator != 'T'
          AND cie.cost_item_id = ci.cost_item_id
          AND cie.budget_code IS NULL
          AND swe.standard_work_element_id(+) = ci.standard_work_element_id
          AND bcfss.scheme_id = sbfm.scheme_id
          AND bcfss.scheme_version = sbfm.scheme_version
          AND bc.budget_code = bcfss.budget_code
          AND bc.date_from = bcfss.budget_code_date_from
          AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
          AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
          AND wc.work_category = wcfs.work_category_1
          AND wca.work_category_1(+) = wcfs.work_category_1
          AND wca.work_category_2(+) = wcfs.work_category_2
          AND non_cont.cost_item_id(+) = sbfm.cost_item_id
          AND non_cont.type_of_cost_ri(+) = 206
          AND cont.cost_item_id(+) = sbfm.cost_item_id
          AND cont.type_of_cost_ri(+) = 207
          AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
        UNION
       SELECT DISTINCT 
                1, 
                nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
                NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                nvl(swe.description_for_customer,ci.description) swe_description,
                sbfm.description,
                sbfm.cost_item_id,
                null
         FROM scheme_breakdown_for_margins sbfm,
              cost_item ci,
              work_category_for_scheme wcfs,
              cost_item_element non_cont,
              cost_item_element cont,
              standard_work_element swe,
              work_category_association wca,
              work_category wc,
              cost_item_allocation$v cia,
             (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
               WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                 AND rsi1.CONTINGENCY_IND = 'Y') ts
        WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
          AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
          AND sbfm.userid = user_pk.get_userid
          AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
          AND ts.scheme_id(+) = sbfm.scheme_id
          AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
          AND ci.cost_item_id = sbfm.cost_item_id
          AND ci.cost_item_indicator != 'T'
          AND cia.cost_item_id = ci.cost_item_id
          AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
          AND cia.split_indicator = 0
          AND swe.standard_work_element_id(+) = ci.standard_work_element_id
          AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
          AND wc.work_category = wcfs.work_category_1
          AND wca.work_category_1(+) = wcfs.work_category_1
          AND wca.work_category_2(+) = wcfs.work_category_2
          AND non_cont.cost_item_id(+) = ci.cost_item_id
          AND non_cont.type_of_cost_ri(+) = 206
          AND cont.cost_item_id(+) = ci.cost_item_id
          AND cont.type_of_cost_ri(+) = 207
        UNION
       SELECT DISTINCT 
                1, 
                nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
                NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                nvl(swe.description_for_customer,cip.description) swe_description,
                sbfm.description,
                sbfm.cost_item_id,null
         FROM scheme_breakdown_for_margins sbfm,
              cost_item ci,
              work_category_for_scheme wcfs,
              cost_item_element non_cont,
              cost_item_element cont,
              standard_work_element swe,
              work_category_association wca,
              work_category wc,
              cost_item_allocation$v cia,
              cost_item cip,
             (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
               WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                 AND rsi1.CONTINGENCY_IND = 'Y') ts
        WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
          AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
          AND sbfm.userid = user_pk.get_userid
          AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
          AND ts.scheme_id(+) = sbfm.scheme_id
          AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
          AND cip.cost_item_id = sbfm.cost_item_id
          AND cip.cost_item_indicator != 'T'
          AND ci.parent_cost_item_id = cip.cost_item_id
          AND cia.cost_item_id = ci.cost_item_id
          AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
          AND cia.split_indicator = 0
          AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
          AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
          AND wc.work_category = wcfs.work_category_1
          AND wca.work_category_1(+) = wcfs.work_category_1
          AND wca.work_category_2(+) = wcfs.work_category_2
          AND non_cont.cost_item_id(+) = sbfm.cost_item_id
          AND non_cont.type_of_cost_ri(+) = 206
          AND cont.cost_item_id(+) = sbfm.cost_item_id
          AND cont.type_of_cost_ri(+) = 207
        UNION   
       SELECT 2,
              sum(CONTESTABLE_COST), 
              sum(NONCONTESTABLE_COST), 
              work_cat_desc,total_quantity, 
              'Travel', 
              budget_code, 
              work_cat_for_scheme_id, 
              null 
        FROM (SELECT  DISTINCT 
                        2, 
                        decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                        decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.noncont_travel_cost,2),ROUND(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                        nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                        0 total_quantity,
                        'Travel',
                        bc.budget_code, 
                        wcfs.work_cat_for_scheme_id,
                        NULL
                 FROM travel_cost_for_margins sbfm,
                      work_category_for_scheme wcfs,
                      work_category_association wca,
                      budget_code bc,
                      work_category wc,
                      cost_item ci,
                     (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                        FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                       WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                         AND rsi1.CONTINGENCY_IND = 'Y') ts			      
                 WHERE wc.work_category(+) = wcfs.work_category_2
                   AND wca.work_category_1(+) = wcfs.work_category_1
                   AND wca.work_category_2(+) = wcfs.work_category_2
                   AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                   AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                   AND ci.scheme_id = sbfm.scheme_id
                   AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                   AND ci.COST_ITEM_INDICATOR = 'T'
                   AND ts.scheme_id(+) = sbfm.scheme_id
                   AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                   AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                   AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                   AND sbfm.scheme_id = wcfs.scheme_id
                   AND sbfm.scheme_version = wcfs.scheme_version
                   AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                   AND sbfm.userid = user_pk.get_userid   
                 UNION
                SELECT  DISTINCT 
                          2, 
                          ROUND(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
                          0 NONCONTESTABLE_COST,
                          nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                          0 total_quantity,
                          'Travel',
                          bc.budget_code, 
                          wcfs.work_cat_for_scheme_id,null
                   FROM travel_cost_for_margins sbfm,
                        work_category_for_scheme wcfs,
                        work_category_association wca,
                        BUDGET_CODE BC,
                        work_category wc,
                        cost_item ci,
                        scheme_version sv,
                        budget_code_margin_applicable bcma,
                       (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                          FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                         WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                           AND rsi1.CONTINGENCY_IND = 'Y') ts			      
                  WHERE wc.work_category(+) = wcfs.work_category_2
                    AND wca.work_category_1(+) = wcfs.work_category_1
                    AND wca.work_category_2(+) = wcfs.work_category_2
                    AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                    AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                    AND ci.scheme_id = sbfm.scheme_id
                    AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                    AND ci.COST_ITEM_INDICATOR = 'T'
                    AND ts.scheme_id(+) = sbfm.scheme_id
                    AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                    AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                    AND sbfm.budget_code = bcma.budget_code
                    AND sbfm.engineering_classification = bcma.engineering_classification
                    AND bcma.dno = v2_dno
                    AND sbfm.budget_code_date_from = bc.date_from            
                    AND sbfm.budget_code_date_from = bcma.budget_code_date_from                
                    AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
                    AND sv.scheme_id = sbfm.scheme_id
                    AND sv.scheme_version = sbfm.scheme_version
                    AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                    AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                    AND sbfm.scheme_id = wcfs.scheme_id
                    AND sbfm.scheme_version = wcfs.scheme_version
                    AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                    AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                    AND sbfm.userid = user_pk.get_userid)
                    GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  CURSOR terms_recovered_asset_dual IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.p2_scheme_version_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID; 
       
      
  CURSOR get_vat_total_amount_dual IS
    SELECT SUM( CONTESTABLE_COST + NONCONTESTABLE_COST )
     FROM (SELECT DISTINCT 
                    1, 
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
                    nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
                    nvl(swe.description_for_customer,ci.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id 
             FROM scheme_breakdown_for_margins sbfm,
                  cost_item ci,
                  cost_item_element cie,
                  cost_item_element	non_cont,
                  cost_item_element	cont,
                  work_category_for_scheme wcfs,
                  standard_work_element swe,
                  work_category wc,
                  work_category_association wca,
                  budget_code_for_scheme_split bcfss,
                  budget_code bc,
                 (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                    FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                   WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     AND rsi1.CONTINGENCY_IND = 'Y') ts
            where SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
              AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
              and sbfm.userid = user_pk.get_userid
              AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
              and ts.scheme_id(+) = sbfm.scheme_id
              and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
              AND ci.cost_item_id = sbfm.cost_item_id
              AND ci.cost_item_indicator != 'T'
              AND cie.cost_item_id = ci.cost_item_id
              AND cie.budget_code IS NULL
              AND swe.standard_work_element_id(+) = ci.standard_work_element_id
              AND bcfss.scheme_id = sbfm.scheme_id
              AND bcfss.scheme_version = sbfm.scheme_version
              and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
              AND bcfss.budget_code = vn_budget_code_dual
              AND bc.date_from = bcfss.budget_code_date_from
              AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
              AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
              AND wc.work_category = wcfs.work_category_1
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND non_cont.cost_item_id(+) = sbfm.cost_item_id
              AND non_cont.type_of_cost_ri(+) = 206
              AND cont.cost_item_id(+) = sbfm.cost_item_id
              AND cont.type_of_cost_ri(+) = 207
              AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
            UNION
           SELECT DISTINCT 
                    1, 
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                    nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                    nvl(swe.description_for_customer,ci.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
             FROM scheme_breakdown_for_margins sbfm,
                  cost_item ci,
                  work_category_for_scheme wcfs,
                  cost_item_element cie,
                  cost_item_element non_cont,
                  cost_item_element cont,
                  standard_work_element swe,
                  work_category_association wca,
                  work_category wc,
                  cost_item_allocation$v cia,
                 (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                    FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                   WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     AND rsi1.CONTINGENCY_IND = 'Y') ts
            WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
              AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
              and sbfm.userid = user_pk.get_userid
              AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
              and ts.scheme_id(+) = sbfm.scheme_id
              and ts.scheme_version(+) = sbfm.SCHEME_VERSION
              AND ci.cost_item_id = sbfm.cost_item_id
              AND ci.cost_item_indicator != 'T'
              and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
              and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
              AND cie.budget_code = vn_budget_code_dual
              AND cia.cost_item_id = ci.cost_item_id
              AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
              AND cia.split_indicator = 0
              AND swe.standard_work_element_id(+) = ci.standard_work_element_id
              AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
              AND wc.work_category = wcfs.work_category_1
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND non_cont.cost_item_id(+) = ci.cost_item_id
              AND non_cont.type_of_cost_ri(+) = 206
              AND cont.cost_item_id(+) = ci.cost_item_id
              AND cont.type_of_cost_ri(+) = 207
            UNION
           SELECT DISTINCT 
                    1, 
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                    nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                    nvl(swe.description_for_customer,cip.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
             FROM scheme_breakdown_for_margins sbfm,
                    cost_item ci,
                    work_category_for_scheme wcfs,
                    cost_item_element cie,       
                    cost_item_element non_cont,
                    cost_item_element cont,
                    standard_work_element swe,
                    work_category_association wca,
                    work_category wc,
                    cost_item_allocation$v cia,
                    cost_item cip,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                      FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                     WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
                AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
                AND sbfm.userid = user_pk.get_userid
                AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION    
                AND cip.cost_item_id = sbfm.cost_item_id
                AND cip.cost_item_indicator != 'T'
                AND ci.parent_cost_item_id = cip.cost_item_id
                AND CIA.COST_ITEM_ID = CI.COST_ITEM_ID
                AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
                AND cie.budget_code = vn_budget_code_dual
                AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                AND cia.split_indicator = 0
                AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
                AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND wc.work_category = wcfs.work_category_1
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND non_cont.cost_item_id(+) = sbfm.cost_item_id
                AND non_cont.type_of_cost_ri(+) = 206
                AND cont.cost_item_id(+) = sbfm.cost_item_id
                AND cont.type_of_cost_ri(+) = 207
              UNION
             SELECT 2,
                    sum(CONTESTABLE_COST), 
                    sum(NONCONTESTABLE_COST),
                    work_cat_desc,
                    total_quantity, 
                    'Travel',
                    budget_code,
                    work_cat_for_scheme_id 
              FROM (SELECT  DISTINCT 
                              2, 
                              decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                              decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.noncont_travel_cost,2),ROUND(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code, 
                              wcfs.work_cat_for_scheme_id
                       FROM travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            budget_code bc,
                            work_category wc,
                            cost_item ci,
                           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                             WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                               AND rsi1.CONTINGENCY_IND = 'Y') ts			      
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        AND wca.work_category_1(+) = wcfs.work_category_1
                        AND wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        AND ci.scheme_id = sbfm.scheme_id
                        AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                        AND ci.COST_ITEM_INDICATOR = 'T'
                        AND bc.budget_code = vn_budget_code_dual
                        AND ts.scheme_id(+) = sbfm.scheme_id
                        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                        AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                        AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                        AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND sbfm.scheme_version = wcfs.scheme_version
                        AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                        AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                        AND sbfm.userid = user_pk.get_userid   
                      UNION
                     SELECT DISTINCT 
                              2, 
                              ROUND(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
                              0 NONCONTESTABLE_COST,
                              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code, 
                              wcfs.work_cat_for_scheme_id
                       from travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            BUDGET_CODE BC,
                            work_category wc,
                            cost_item ci,
                            scheme_version sv,
                            budget_code_margin_applicable bcma,
                           (SELECT rsi1.contingency_ind "CONTINGENCY_IND" , rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version 
                              FROM terms_split ts1, recharge_statement_info rsi1 
                             WHERE ts1.terms_split_id = rsi1.terms_split_id
                               AND rsi1.contingency_ind = 'Y') ts			      
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        AND wca.work_category_1(+) = wcfs.work_category_1
                        AND wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 or sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        AND ci.scheme_id = sbfm.scheme_id
                        AND ci.scheme_version = sbfm.scheme_version
                        AND ci.cost_item_indicator = 'T'
                        AND bc.budget_code = vn_budget_code_dual
                        AND ts.scheme_id(+) = sbfm.scheme_id
                        AND ts.scheme_version(+) = sbfm.scheme_version
                        AND sbfm.budget_code = bc.budget_code
                        AND sbfm.budget_code = bcma.budget_code
                        AND sbfm.engineering_classification = bcma.engineering_classification
                        AND bcma.dno = v2_dno
                        AND sbfm.budget_code_date_from = bc.date_from            
                        AND sbfm.budget_code_date_from = bcma.budget_code_date_from                
                        AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
                        AND sv.scheme_id = sbfm.scheme_id
                        AND sv.scheme_version = sbfm.scheme_version
                        AND bc.type_of_expenditure_ri IN (vn_expenditure_type1_dual, vn_expenditure_type2_dual)
                        AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND sbfm.scheme_version = wcfs.scheme_version
                        AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                        AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                        AND sbfm.userid = user_pk.get_userid)
                      GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
                      UNION
                     SELECT 2,
                            SUM(ROUND(sbfm.fees_cost)) contestable_cost,
                            0 noncontestable_cost,
                            '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
                       FROM scheme_breakdown_for_margins sbfm, 
                            cost_item ci,
                            cost_item_element cie,
                            work_category_for_scheme wcfs,
                            work_category wc,
                            historic_swe hs
                      WHERE sbfm.cost_item_id = ci.cost_item_id
                        AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND wcfs.work_category_2(+) = wc.work_category
                        AND sbfm.fees_cost > 0 
                        AND SBFM.DESCRIPTION = 'FEES'
                        AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
                        AND cie.budget_code = vn_budget_code_dual
                        AND sbfm.standard_work_element_id = hs.standard_work_element_id
                        AND hs.date_to is null
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
                        AND SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
                        AND SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
                        AND sbfm.userid = user_pk.get_userid
                      GROUP BY WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
                      UNION
                     SELECT DISTINCT 
                              2, 
                              (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
                              0 NONCONTESTABLE_COST,
                              '0' work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
                       FROM terms_split ts,
                            budget_code bc,
                            terms_budget_code_for_cat tbcfc,
                            terms_budget_cat_for_scheme tbcfs
                      WHERE tbcfs.scheme_id = :parameter.p2_scheme_id_dual
                        AND tbcfs.scheme_version = :parameter.p2_scheme_version_dual
                        AND tbcfs.terms_budget_cat_id=tbcfc.terms_budget_cat_id
                        AND tbcfc.budget_code=bc.budget_code
                        AND tbcfc.budget_code_date_from=bc.date_from
                        AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                        AND bc.budget_code = vn_budget_code_dual
                        AND 1 = vn_loop_counter
                        AND tbcfs.terms_budget_cat_id=ts.terms_budget_cat_id)
                      GROUP BY 1;

  CURSOR get_budget_code_dual IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id_dual
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;        

  CURSOR user_applied_terms_vat_dual IS
    SELECT uatgs.quantity, ri.number_field1 
      FROM user_appl_terms_gen_stan uatgs, 
           crown_owner.reference_item ri
     WHERE ri.reference_item_id = uatgs.vat_type_ri
       AND uatgs.terms_split_id = vn_terms_split_id_dual;     
     
  CURSOR c_get_vat IS
    SELECT sum(ROUND(vat_total_cost,2))
      FROM conn_letter_budget_vat
     WHERE scheme_id = :parameter.p2_scheme_id_dual
       AND scheme_version = :parameter.p2_scheme_version_dual;
      
  CURSOR get_vat_rate_dual IS
    SELECT quantity
      FROM terms_general_standard
     WHERE terms_general_standard_id IN (SELECT t.terms_general_standard_id 
                                           FROM terms_general_standard t
                                          WHERE t.terms_general_standard_id IN (SELECT t.terms_general_standard_id
                                                                                  FROM user_appl_terms_gen_stan u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri = 1339
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL 
                                                                                   AND t.terms_general_standard_id = u.terms_general_standard_id
                                                                                   AND u.terms_split_id(+) = vn_terms_split_id_dual
                                                                                 UNION
                                                                                SELECT t.terms_general_standard_id
                                                                                  FROM user_appl_terms_gen_stan u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri     =1339
                                                                                   AND t.terms_standard_ri =1337
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL
                                                                                   AND t.terms_general_standard_id = u.terms_general_standard_id(+)
                                                                                   AND u.terms_split_id(+)= vn_terms_split_id_dual
                                                                                   AND NOT EXISTS (SELECT 1 
                                                                                                     FROM user_appl_terms_gen_stan 
                                                                                                    WHERE terms_split_id = vn_terms_split_id_dual)
                                                                                )
                                        );

BEGIN

  v2_dno := crown_owner.util_scheme_procs.get_dno_for_scheme(:parameter.p2_scheme_id_dual, :parameter.p2_scheme_version_dual);

  OPEN terms_split_id_dual;
  FETCH terms_split_id_dual
  INTO vn_terms_split_id_dual;
  CLOSE terms_split_id_dual;

	OPEN budget_category_dual;
	FETCH budget_category_dual
	INTO v2_budget_cat_ind_dual;
	CLOSE budget_category_dual;
	
  IF v2_budget_cat_ind_dual IN ('E','N')  THEN
    vn_expenditure_type1_dual := 226;
    vn_expenditure_type2_dual := 227;
  ELSE
    vn_expenditure_type1_dual := 258;
  END IF;  

  IF vn_expenditure_type1_dual = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:parameter.p2_scheme_version_dual,user_pk.get_userid,vn_expenditure_type1_dual);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:parameter.p2_scheme_version_dual,user_pk.get_userid);    
  END IF;

  vn_new_cont_dual      := 0;
  vn_new_fees_dual      := 0;
  vn_new_non_cont_dual  := 0;
  vn_total_cost_dual    := 0;
  vn_reg_payment_dual   := 0;
  vn_total_charge_dual  := 0;
    
  FOR get_rec IN get_fees_dual LOOP
    vn_new_fees_dual := vn_new_fees_dual+get_rec.fees;
  END LOOP;
  
  :terms_connection_letters_sbk.non_cont_2 := vn_new_fees_dual;
  
  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
    
  FOR get_rec IN new_costs_dual LOOP
  	vn_new_cont_dual := vn_new_cont_dual + get_rec.contestable_cost;
  	vn_new_non_cont_dual := vn_new_non_cont_dual + get_rec.noncontestable_cost;
  END LOOP;
  
  :terms_connection_letters_sbk.non_cont_works_2 := vn_new_non_cont_dual;

  OPEN terms_recovered_asset_dual;
	FETCH terms_recovered_asset_dual
  INTO vn_reg_payment_dual;
	CLOSE terms_recovered_asset_dual;
	
	:terms_connection_letters_sbk.reg_connect_charge_2 := vn_reg_payment_dual;	
  vn_total_charge_dual := NVL(vn_new_cont_dual,0) + NVL(vn_new_non_cont_dual,0) + NVL(vn_new_fees_dual,0) + NVL(vn_reg_payment_dual,0);
	:terms_connection_letters_sbk.connection_charge_2 := vn_total_charge_dual;

  DELETE 
    FROM conn_letter_budget_vat
   WHERE scheme_id = :parameter.p2_scheme_id_dual
     AND scheme_version = :parameter.p2_scheme_version_dual;
  COMMIT;

  -- Open Cursor To Get Number Of Budget Codes And Loop ROUND For Each One
	vn_vat_total_cost_dual  := 0;
	vn_total_cost_vat_dual  := 0;
  vn_loop_counter         := 1;
	vn_total_customers_dual := 0;
	
  FOR get_rec IN get_budget_code_dual LOOP
  	vn_cost_per_bc_dual     := 0;
  	vn_budget_code_dual     := NULL;
  	vn_total_customers_dual := NULL;
  	vn_terms_split_id_dual  := NULL;
  	
  	vn_budget_code_dual     := get_rec.budget_code;
    vn_total_customers_dual := get_rec.number_of_connections;
    vn_terms_split_id_dual  := get_rec.terms_split_id;

    -- Open Cursor To Get Vat_Total_Amount
    OPEN get_vat_total_amount_dual;
    FETCH get_vat_total_amount_dual
    INTO vn_cost_per_bc_dual;
    CLOSE get_vat_total_amount_dual;
    
    -- If Cost Is Greater Then 0 Carry On
    IF vn_cost_per_bc_dual > 0 THEN
    	
      -- Use Number Of Connections To Divide The Vn_Total_Amount Into Vn_Cost_Per_Customer    	
      vn_cost_per_customer_dual := ROUND(vn_cost_per_bc_dual/vn_total_customers_dual,2);

      -- Open Cursor User_Applied_Terms_Vat To Get Vat_Rate And Number Of Quantity At Vat Rate And Loop      
      FOR get_rec IN user_applied_terms_vat_dual LOOP
      	vn_vat_rate_dual := NULL;     	
        vn_cust_per_vat_rate_dual := NULL;
              	
        vn_cust_per_vat_rate_dual := get_rec.quantity;
      	vn_vat_rate_dual := get_rec.number_field1;
        
        -- Multiply The Number Of Connections With Vn_Cost_Per_Customer Into Vn_Cust_Per_Vat_Rate      	
      	vn_cost_per_vat_rate_dual := ROUND(vn_cost_per_customer_dual*vn_cust_per_vat_rate_dual,2);
      	
        -- Multiply Vn_Cost_Per_Vat_Rate With Vat Rate To Get Vn_Total_Cost_Vat Rate
        vn_total_cost_vat_dual := ROUND(vn_vat_rate_dual*vn_cost_per_vat_rate_dual,2)/100;

        --If More Then One Vat Rate Concat Vn_Total
	      insert into conn_letter_budget_vat(scheme_id,scheme_version,budget_code,vat_rate,total_cost,vat_total_cost)
	      values (:parameter.p2_scheme_id_dual,:parameter.P2_SCHEME_VERSION_dual,vn_budget_code_dual,vn_vat_rate_dual,vn_cost_per_vat_rate_dual,vn_total_cost_vat_dual);
	      
        COMMIT;
	      vn_loop_counter         := vn_loop_counter+1;
	      vn_vat_total_cost_dual  := vn_vat_total_cost_dual + vn_total_cost_vat_dual;
              
      END LOOP;
    END IF;
  END LOOP;

  OPEN c_get_vat;
  FETCH c_get_vat
  INTO vn_vat_dual;
  CLOSE c_get_vat;

  UPDATE TERMS_CONNECTION_LETTERS
     SET VAT_2 = vn_vat_dual
   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;

  COMMIT;
  Go_block('TERMS_CONNECTION_LETTERS_SBK');
  execute_query;

  :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := vn_vat_dual;
  
  OPEN get_vat_rate_dual;
  FETCH get_vat_rate_dual
  INTO vn_vat_rate_new_dual;
  CLOSE get_vat_rate_dual;
  
  :TERMS_CONNECTION_LETTERS_SBK.OPTION_2_VAT_RATE := vn_vat_rate_new_dual;
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_2 := ROUND(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_2,0)+vn_total_charge_dual,2);

  COMMIT;
	go_block('TERMS_CONNECTION_LETTERS_SBK');
	execute_query;

END;

--- rt_demand_letter\rdl_old_generate_costs.pl ---
PROCEDURE generate_costs IS
		vn_alert 				NUMBER;
  vn_expenditure_type1 NUMBER;
  vn_expenditure_type2 NUMBER;
  vn_expenditure_type1_dual NUMBER;
  vn_expenditure_type2_dual NUMBER;
  v2_budget_cat_ind		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  v2_budget_cat_ind_dual		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
 -- vn_terms_split_id		 number;  
  vn_new_cont number;
  vn_new_non_cont number;   
  vn_total_cost number; 
  vn_reg_payment NUMBER;
  vn_total_charge NUMBER;
  vn_new_fees NUMBER;
  vn_vat_rate							NUMBER;
  
  
--
-- get main costs cursors
--
      CURSOR terms_split_id IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

    
  	CURSOR budget_category IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION;  

--
-- CCN13700 start
--
	     
  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id
       AND scheme_version = :parameter.p2_scheme_version;
     
  vd_date_of_estimate DATE; 
  v2_quantity NUMBER(3);
  
  CURSOR get_quantity IS
  SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
AND trunc(vd_date_of_estimate) BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate)); 	     
	     
	     

    CURSOR new_costs IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,bc.budget_code 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.p2_scheme_version
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,NULL
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.p2_scheme_version
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id,null
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.p2_scheme_version
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id, null FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;


  vn_past_code_amount   	NUMBER;     


  CURSOR terms_recovered_asset IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.P2_SCHEME_ID
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;    

  CURSOR get_fees Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.P2_SCHEME_ID
and sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

--CCN10061 Start bc/vat rate changes full

  vn_budget_code	     varchar2(3);
  vn_cost_per_bc       number;
  vn_cost_per_customer number;
  vn_total_customers   number;
  vn_cost_per_vat_rate number;
  vn_total_cost_vat    number;
  vn_terms_split_id		 number;
  vn_pre_vat_text      VARCHAR2(250);
  vn_vat_total_text    VARCHAR2(250);
  vn_pre_vat_text_final      VARCHAR2(500);
  vn_vat_total_text_final    VARCHAR2(500);
  vn_vat_total_cost    number;
  vn_loop_counter NUMBER;

--
--CCN13700 start
--
      
CURSOR get_vat_total_amount IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and bc.budget_code = vn_budget_code
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and bc.budget_code = vn_budget_code
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1,vn_expenditure_type2)
       AND BC.BUDGET_CODE = vn_budget_code
       AND 1 = vn_loop_counter
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

  vn_cust_per_vat_rate NUMBER;
  
  CURSOR user_applied_terms_vat IS
   select uatgs.QUANTITY, ri.NUMBER_FIELD1 
     from USER_APPL_TERMS_GEN_STAN uatgs, 
          CROWN_OWNER.REFERENCE_ITEM ri
    where ri.REFERENCE_ITEM_ID = uatgs.VAT_TYPE_RI
      and uatgs.TERMS_SPLIT_ID = vn_terms_split_id;
     
--CCN06164 End bc/vat rate changes full

--
-- dual offer cursors
-- 

    vn_new_cont_dual NUMBER;
    vn_new_fees_dual NUMBER;
    vn_new_non_cont_dual NUMBER;
    vn_total_cost_dual NUMBER;
    vn_reg_payment_dual NUMBER;
    vn_total_charge_dual NUMBER; 
    vn_vat_rate_dual number;
 --   vn_terms_split_id_dual		 number;     
    
      CURSOR terms_split_id_dual IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;    
    

  	CURSOR budget_category_dual IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;  

  CURSOR get_fees_dual Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

    CURSOR new_costs_dual IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
    select 2, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
 from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid;

  vn_past_code_amount_dual   	NUMBER;     
  CURSOR terms_recovered_asset_dual IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.p2_scheme_version_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID; 
       
--CCN10061 Start bc/vat rate changes dual

  vn_budget_code_dual	     varchar2(3);
  vn_cost_per_bc_dual       number;
  vn_cost_per_customer_dual number;
  vn_total_customers_dual   number;
  vn_cost_per_vat_rate_dual number;
  vn_total_cost_vat_dual    number;
  vn_terms_split_id_dual		 number;
  vn_pre_vat_text_dual      VARCHAR2(250);
  vn_vat_total_text_dual    VARCHAR2(250);
  vn_pre_vat_text_final_dual      VARCHAR2(500);
  vn_vat_total_text_final_dual    VARCHAR2(500);
  vn_vat_total_cost_dual    number;
      
CURSOR get_vat_total_amount_dual IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code_dual
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
    select 2, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
 from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
and SBFM.BUDGET_CODE = BC.BUDGET_CODE
AND bc.budget_code = vn_budget_code_dual
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code_dual
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
       AND BC.BUDGET_CODE = vn_budget_code_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code_dual IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id_dual
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;


  CURSOR user_applied_terms_vat_dual IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_dual)));
         
     
--CCN10061 End bc/vat rate changes dual


                    vn_a_d_fee NUMBER;
                    vn_a_d_fee_vat_total NUMBER;
                    vn_a_d_fee_inc_vat NUMBER;
                    vn_ad_vat_rate NUMBER;

  CURSOR get_a_d_fee IS
    SELECT NVL(SUM(round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',sbfm.fees_cost,sbfm.fees_cost*nvl(ts.CONTINGENCY_AMOUNT,0)/100+sbfm.fees_cost))),0) As "A_D"
      FROM scheme_breakdown_for_margins sbfm, 
           cost_item ci, 
           work_category_for_scheme wcfs,
                         work_category wc,
                         historic_swe hs,
                        (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                           from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                          where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                            and rsi1.CONTINGENCY_IND = 'Y') ts
                  WHERE sbfm.cost_item_id = ci.cost_item_id
                    AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                  AND wcfs.work_category_2(+) = wc.work_category
                    AND sbfm.fees_cost > 0 
                    AND sbfm.description = 'FEES'
                    AND wc.work_category like '%Design%'
                    AND ts.scheme_id(+) = sbfm.scheme_id
                    AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                    AND sbfm.standard_work_element_id = hs.standard_work_element_id
                    AND hs.date_to is null
                    AND sbfm.scheme_id = wcfs.scheme_id
                    AND sbfm.scheme_version = wcfs.scheme_version
                    and sbfm.userid = user_pk.get_userid
                    AND sbfm.scheme_id = :PARAMETER.P2_SCHEME_ID
                    AND sbfm.scheme_version = :PARAMETER.P2_SCHEME_VERSION;
                    


    CURSOR get_vat_rate IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id)));


BEGIN
	
--
-- Populate table with costs for main scheme
--



    OPEN terms_split_id;
    FETCH terms_split_id
    INTO vn_terms_split_id;
    CLOSE terms_split_id;

	OPEN budget_category;
	FETCH budget_category
	INTO v2_budget_cat_ind;
	CLOSE budget_category;
	

	
  IF v2_budget_cat_ind IN ('E','N')  THEN
    vn_expenditure_type1 := 226;
    vn_expenditure_type2 := 227;
  ELSE
    vn_expenditure_type1 := 258;
  END IF;  

message('Calculating Costs 10%',NO_ACKNOWLEDGE);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 10%';
  
  IF vn_expenditure_type1 = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:PARAMETER.P2_SCHEME_VERSION,user_pk.get_userid,vn_expenditure_type1);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:PARAMETER.P2_SCHEME_VERSION,user_pk.get_userid);    
  END IF;
 -- commit;
SYNCHRONIZE;
message('Calculating Costs 20%',NO_ACKNOWLEDGE);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 20%';
--
-- get fees
--
    vn_new_cont :=0;
    vn_new_fees :=0;
    vn_new_non_cont :=0;
    vn_total_cost :=0;
    vn_reg_payment :=0;
    vn_total_charge := 0;
  for get_rec IN get_fees LOOP
    vn_new_fees := vn_new_fees+get_rec.fees;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_1 := vn_new_fees;

--
-- CCN13700 start
--
  
  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
  
  OPEN get_quantity;
  FETCH get_quantity
  INTO v2_quantity;
  CLOSE get_quantity;

--
-- CCN13700 END
--

 
--
-- get non-contestable costs
--
  for get_rec IN new_costs LOOP
  	vn_new_cont := vn_new_cont+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont := vn_new_non_cont+get_rec.NONCONTESTABLE_COST;
  end LOOP;
SYNCHRONIZE;  
message('Calculating Costs 30%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 30%';   
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_1 := vn_new_non_cont;
--
-- get contestable costs
--
SYNCHRONIZE;
message('Calculating Costs 40%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 40%';

 :TERMS_CONNECTION_LETTERS_SBK.CONTESTABLE_WORKS_1 := vn_new_cont;
--
-- get ECCR payment
--
  OPEN terms_recovered_asset;
	FETCH terms_recovered_asset
  INTO vn_reg_payment;
	CLOSE terms_recovered_asset;
SYNCHRONIZE;
message('Calculating Costs 50%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 50%';
	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_1 := vn_reg_payment;


-- 
-- get connection charge ex vat
--
  vn_total_charge := NVL(vn_new_cont,0)+NVL(vn_new_non_cont,0)+NVL(vn_new_fees,0)+NVL(vn_reg_payment,0);
SYNCHRONIZE;
message('Calculating Costs 60%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 60%';  
	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_1 := vn_total_charge;
	SYNCHRONIZE;
message('Calculating Costs 70%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 70%';
--
-- get vat amount
--

--
-- CCN10061 start bc/vat split full
--
  delete from conn_letter_budget_vat
  where scheme_id = :parameter.p2_scheme_id
   and scheme_version = :parameter.P2_SCHEME_VERSION;
  commit;

--open cursor to get number of budget codes and loop round for each one
	vn_vat_total_cost := 0;
	vn_total_cost_vat := 0;
	vn_loop_counter := 1;

	vn_total_customers :=0;
  FOR get_rec IN get_budget_code LOOP
  	vn_cost_per_bc := 0;
  	vn_budget_code := NULL;
  	vn_total_customers := NULL;
  	vn_terms_split_id := NULL;
  	
  	vn_budget_code := get_rec.budget_code;
    vn_total_customers := get_rec.number_of_connections;
    vn_terms_split_id := get_rec.terms_split_id;

--open cursor to get vat_total_amount

    OPEN get_vat_total_amount;
    FETCH get_vat_total_amount
    INTO vn_cost_per_bc;
    CLOSE get_vat_total_amount; 
    
--if cost is greater then 0 carry on
    IF vn_cost_per_bc >0 THEN
    	
--use number of connections to divide the vn_total_amount into vn_cost_per_customer    	
      vn_cost_per_customer := round(vn_cost_per_bc/vn_total_customers,2);
--open cursor user_applied_terms_vat to get vat_rate and number of quantity at vat rate and loop      
      FOR get_rec IN user_applied_terms_vat LOOP
 --     	vn_total_customers := NULL;
      	vn_vat_rate := NULL;
        vn_cust_per_vat_rate := NULL;	     	
      	
 --     	vn_total_customers := get_rec.customers;
        vn_cust_per_vat_rate := get_rec.quantity;
      	vn_vat_rate := get_rec.number_field1;
--multiply the number of connections with vn_cost_per_customer into vn_cust_per_vat_rate      	
      	vn_cost_per_vat_rate := round(vn_cost_per_customer*vn_cust_per_vat_rate,2);
      	--multiply vn_cost_per_vat_rate with vat rate to get vn_total_cost_vat rate
        vn_total_cost_vat := round(vn_vat_rate*vn_cost_per_vat_rate,2)/100;
--if more then one vat rate concat vn_total    
	      
	      IF vn_budget_code = 'RC' THEN 
	      	vn_budget_code := 0;
        END IF;	      	
SYNCHRONIZE;
message('Calculating Costs 80%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 80%';
         	      	      
	      insert into conn_letter_budget_vat(scheme_id,scheme_version,budget_code,vat_rate,total_cost,vat_total_cost)
	      values(:parameter.p2_scheme_id,:parameter.P2_SCHEME_VERSION,vn_budget_code,vn_vat_rate,vn_cost_per_vat_rate,vn_total_cost_vat);
	      commit;
	      vn_loop_counter := vn_loop_counter+1;      
	      
	      vn_vat_total_cost := vn_vat_total_cost+vn_total_cost_vat;  	      

      END LOOP;
    END IF;
  END LOOP;
SYNCHRONIZE;
message('Calculating Costs 90%',no_acknowledge); 
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 90%';
  :TERMS_CONNECTION_LETTERS_SBK.VAT_1 := vn_vat_total_cost;

--
-- CCN10061 end bc/vat split full
-- 


--
-- get connection charge inc vat
--
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_1 := round(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_1,0)+vn_total_charge,2);


  OPEN get_vat_rate;
  FETCH get_vat_rate
  INTO vn_ad_vat_rate;
  CLOSE get_vat_rate;


  OPEN get_a_d_fee;
  FETCH get_a_d_fee
  INTO vn_a_d_fee;
  CLOSE get_a_d_fee;
  
:TERMS_CONNECTION_LETTERS_SBK.OPTION_1_VAT_RATE := vn_ad_vat_rate;
  
  IF vn_a_d_fee >0 THEN
  
    vn_a_d_fee_vat_total := vn_a_d_fee*vn_ad_vat_rate/100;
    vn_a_d_fee_inc_vat   := vn_a_d_fee+vn_a_d_fee_vat_total;



    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_prevat := vn_a_d_fee;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_vat    := vn_a_d_fee_vat_total;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_total  := vn_a_d_fee_inc_vat;
  
  ELSE
  	
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_prevat := 0;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_vat    := 0;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_total  := 0;  	
  END IF;
SYNCHRONIZE;  
message('Calculating Costs 100%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 100%'; 
  commit;
		go_block('TERMS_CONNECTION_LETTERS_SBK');
		execute_query;

END;

--- rt_demand_letter\rdl_old_generate_costs_dual.pl ---
PROCEDURE GENERATE_COSTS_DUAL IS
		vn_alert 				NUMBER;

  vn_expenditure_type1_dual NUMBER;
  vn_expenditure_type2_dual NUMBER;
  vn_vat_dual NUMBER;

  v2_budget_cat_ind_dual		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;


--
-- dual offer cursors
-- 

    vn_new_cont_dual NUMBER;
    vn_new_fees_dual NUMBER;
    vn_new_non_cont_dual NUMBER;
    vn_total_cost_dual NUMBER;
    vn_reg_payment_dual NUMBER;
    vn_total_charge_dual NUMBER; 
    vn_vat_rate_dual number;
 --   vn_terms_split_id_dual		 number;     
    
      CURSOR terms_split_id_dual IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;    
    

  	CURSOR budget_category_dual IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;  

  CURSOR get_fees_dual Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id_dual
       AND scheme_version = :parameter.p2_scheme_version_dual;
     
  vd_date_of_estimate DATE; 
  v2_quantity NUMBER(3);
  
  CURSOR get_quantity IS
  SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
AND trunc(vd_date_of_estimate) BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate)); 


    CURSOR new_costs_dual IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,bc.budget_code 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,null
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id,null
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id,null FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  vn_past_code_amount_dual   	NUMBER;     
  CURSOR terms_recovered_asset_dual IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.p2_scheme_version_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID; 
       
--CCN10061 Start bc/vat rate changes dual

  vn_budget_code_dual	     varchar2(3);
  vn_cost_per_bc_dual       number;
  vn_cost_per_customer_dual number;
  vn_total_customers_dual   number;
  vn_cost_per_vat_rate_dual number;
  vn_total_cost_vat_dual    number;
  vn_terms_split_id_dual		 number;
  vn_pre_vat_text_dual      VARCHAR2(250);
  vn_vat_total_text_dual    VARCHAR2(250);
  vn_pre_vat_text_final_dual      VARCHAR2(500);
  vn_vat_total_text_final_dual    VARCHAR2(500);
  vn_vat_total_cost_dual    number;
  vn_loop_counter	NUMBER;
      
CURSOR get_vat_total_amount_dual IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code_dual
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
AND bc.budget_code = vn_budget_code_dual
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
AND bc.budget_code = vn_budget_code_dual
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code_dual
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
       AND BC.BUDGET_CODE = vn_budget_code_dual
       AND 1 = vn_loop_counter
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code_dual IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id_dual
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;
       
  vn_cust_per_vat_rate_dual NUMBER;

  CURSOR user_applied_terms_vat_dual IS
   select uatgs.QUANTITY, ri.NUMBER_FIELD1 
     from USER_APPL_TERMS_GEN_STAN uatgs, 
          CROWN_OWNER.REFERENCE_ITEM ri
    where ri.REFERENCE_ITEM_ID = uatgs.VAT_TYPE_RI
      and uatgs.TERMS_SPLIT_ID = vn_terms_split_id_dual;
     
     
     CURSOR get_vat IS
       SELECT sum(ROUND(vat_total_cost,2))
         FROM conn_letter_budget_vat
        WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
          AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;
         
     
--CCN10061 End bc/vat rate changes dual

    vn_vat_rate_new_dual      NUMBER;

    CURSOR get_vat_rate_dual IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_dual)));


BEGIN

--
-- Populate table with costs for dual offer
--

    OPEN terms_split_id_dual;
    FETCH terms_split_id_dual
    INTO vn_terms_split_id_dual;
    CLOSE terms_split_id_dual;

	OPEN budget_category_dual;
	FETCH budget_category_dual
	INTO v2_budget_cat_ind_dual;
	CLOSE budget_category_dual;
	

	
  IF v2_budget_cat_ind_dual IN ('E','N')  THEN
    vn_expenditure_type1_dual := 226;
    vn_expenditure_type2_dual := 227;
  ELSE
    vn_expenditure_type1_dual := 258;
  END IF;  

--message('calculating dual costs 10%',NO_ACKNOWLEDGE); 

  IF vn_expenditure_type1_dual = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid,vn_expenditure_type1_dual);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid);    
  END IF;
 -- commit;
  
--SYNCHRONIZE;
--message('calculating dual costs 20%',NO_ACKNOWLEDGE);
--
-- get fees
--
    vn_new_cont_dual :=0;
    vn_new_fees_dual :=0;
    vn_new_non_cont_dual :=0;
    vn_total_cost_dual :=0;
    vn_reg_payment_dual :=0;
    vn_total_charge_dual := 0;
    
  for get_rec IN get_fees_dual LOOP
    vn_new_fees_dual := vn_new_fees_dual+get_rec.fees;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_2 := vn_new_fees_dual;
  
  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
  
  OPEN get_quantity;
  FETCH get_quantity
  INTO v2_quantity;
  CLOSE get_quantity;
  
--  SYNCHRONIZE;
--message('calculating dual costs 30%',NO_ACKNOWLEDGE);
--
-- get non-contestable costs
--
  for get_rec IN new_costs_dual LOOP
  	vn_new_cont_dual := vn_new_cont_dual+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont_dual := vn_new_non_conT_dual+get_rec.NONCONTESTABLE_COST;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_2 := vn_new_non_cont_dual;
--
-- get ECCR payment
--
  OPEN terms_recovered_asset_dual;
	FETCH terms_recovered_asset_dual
  INTO vn_reg_payment_dual;
	CLOSE terms_recovered_asset_dual;
	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_2 := vn_reg_payment_dual;
	
-- 
-- get connection charge ex vat
--
  vn_total_charge_dual := NVL(vn_new_cont_dual,0)+NVL(vn_new_non_cont_dual,0)+NVL(vn_new_fees_dual,0)+NVL(vn_reg_payment_dual,0);

	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_2 := vn_total_charge_dual;
--  SYNCHRONIZE;
--message('calculating dual costs 40%',NO_ACKNOWLEDGE);
--
-- get vat amount
--

--
-- CCN10061 start bc/vat split daul
--

  delete from conn_letter_budget_vat
  where scheme_id = :PARAMETER.P2_SCHEME_ID_dual
    and scheme_version = :PARAMETER.P2_SCHEME_VERSION_dual;
  commit;


--open cursor to get number of budget codes and loop round for each one
	vn_vat_total_cost_dual := 0;
	vn_total_cost_vat_dual := 0;
--	vn_pre_vat_text_final := NULL;
--	vn_vat_total_text_final := NULL;
 vn_loop_counter := 1;
--SYNCHRONIZE;
--message('calculating dual costs 50%',NO_ACKNOWLEDGE);
	vn_total_customers_dual :=0;
	
  FOR get_rec IN get_budget_code_dual LOOP
  	vn_cost_per_bc_dual := 0;
  	vn_budget_code_dual := NULL;
  	vn_total_customers_dual := NULL;
  	vn_terms_split_id_dual := NULL;
  	
  	vn_budget_code_dual := get_rec.budget_code;
    vn_total_customers_dual := get_rec.number_of_connections;
    vn_terms_split_id_dual := get_rec.terms_split_id;

--open cursor to get vat_total_amount

    OPEN get_vat_total_amount_dual;
    FETCH get_vat_total_amount_dual
    INTO vn_cost_per_bc_dual;
    CLOSE get_vat_total_amount_dual;
    
--if cost is greater then 0 carry on
    IF vn_cost_per_bc_dual >0 THEN
    	
--use number of connections to divide the vn_total_amount into vn_cost_per_customer    	
      vn_cost_per_customer_dual := round(vn_cost_per_bc_dual/vn_total_customers_dual,2);
--open cursor user_applied_terms_vat to get vat_rate and number of quantity at vat rate and loop      
      FOR get_rec IN user_applied_terms_vat_dual LOOP
 --     	vn_total_customers := NULL;
      	vn_vat_rate_dual := NULL;     	
        vn_cust_per_vat_rate_dual := NULL;
              	
 --     	vn_total_customers := get_rec.customers;
        vn_cust_per_vat_rate_dual := get_rec.quantity;
      	vn_vat_rate_dual := get_rec.number_field1;
--multiply the number of connections with vn_cost_per_customer into vn_cust_per_vat_rate      	
      	vn_cost_per_vat_rate_dual := round(vn_cost_per_customer_dual*vn_cust_per_vat_rate_dual,2);
      	--multiply vn_cost_per_vat_rate with vat rate to get vn_total_cost_vat rate
        vn_total_cost_vat_dual := round(vn_vat_rate_dual*vn_cost_per_vat_rate_dual,2)/100;
--if more then one vat rate concat vn_total
	      insert into conn_letter_budget_vat(scheme_id,scheme_version,budget_code,vat_rate,total_cost,vat_total_cost)
	      values(:parameter.p2_scheme_id_dual,:parameter.P2_SCHEME_VERSION_dual,vn_budget_code_dual,vn_vat_rate_dual,vn_cost_per_vat_rate_dual,vn_total_cost_vat_dual);
	      commit;
	      vn_loop_counter := vn_loop_counter+1;
	      vn_vat_total_cost_dual := vn_vat_total_cost_dual+vn_total_cost_vat_dual;
      
      END LOOP;
    END IF;
END LOOP;
--SYNCHRONIZE;
--message('calculating dual costs 60%',NO_ACKNOWLEDGE);
      OPEN get_vat;
      FETCH get_vat
      INTO vn_vat_dual;
      CLOSE get_vat;
  
 
      
      
 -- :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := vn_vat_dual;
    
    UPDATE TERMS_CONNECTION_LETTERS
	      SET VAT_2 = vn_vat_dual
	    WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
	      AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;
	    COMMIT;
	    Go_block('TERMS_CONNECTION_LETTERS_SBK');
		  execute_query;
--SYNCHRONIZE;
--message('calculating dual costs 70%',NO_ACKNOWLEDGE);		  
--
-- CCN10061 end bc/vat split dual
--  
  :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := vn_vat_dual;
  
  OPEN get_vat_rate_dual;
  FETCH get_vat_rate_dual
  INTO vn_vat_rate_new_dual;
  CLOSE get_vat_rate_dual;
  
  :TERMS_CONNECTION_LETTERS_SBK.OPTION_2_VAT_RATE := vn_vat_rate_new_dual;
--  SYNCHRONIZE;
--message('calculating dual costs 80%',NO_ACKNOWLEDGE);
--
-- get connection charge inc vat
--
--SYNCHRONIZE;
--message('calculating dual costs 80%',NO_ACKNOWLEDGE);
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_2 := round(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_2,0)+vn_total_charge_dual,2);
--SYNCHRONIZE;
--message('calculating dual costs 100%',NO_ACKNOWLEDGE);

  commit;
		go_block('TERMS_CONNECTION_LETTERS_SBK');
		execute_query;

END;

--- rt_generation_letter\rgl_new_generate_costs copy.pl ---
PROCEDURE generate_costs IS
		vn_alert 				NUMBER;
  vn_expenditure_type1 NUMBER;
  vn_expenditure_type2 NUMBER;
  vn_expenditure_type1_dual NUMBER;
  vn_expenditure_type2_dual NUMBER;
  v2_budget_cat_ind		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  v2_budget_cat_ind_dual		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
 -- vn_terms_split_id		 number;  
  vn_new_cont number;
  vn_new_non_cont number;   
  vn_total_cost number; 
  vn_reg_payment NUMBER;
  vn_total_charge NUMBER;
  vn_new_fees NUMBER;
  vn_vat_rate							NUMBER;
  
  
--
-- get main costs cursors
--
  CURSOR terms_split_id IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

    
  CURSOR budget_category IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION;  

--
-- CCN13700 start
--
	     
  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id
       AND scheme_version = :parameter.p2_scheme_version;
     
  vd_date_of_estimate DATE; 
  
  CURSOR get_quantity IS
  SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
AND trunc(vd_date_of_estimate) BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate)); 	     
	     
	     

    CURSOR new_costs IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,bc.budget_code 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.p2_scheme_version
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,NULL
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.p2_scheme_version
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id,null
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.p2_scheme_version
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id, null FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;


  vn_past_code_amount   	NUMBER;     


  CURSOR terms_recovered_asset IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.P2_SCHEME_ID
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;    

  CURSOR get_fees Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.P2_SCHEME_ID
and sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

--CCN10061 Start bc/vat rate changes full

  vn_budget_code	     varchar2(3);
  vn_cost_per_bc       number;
  vn_cost_per_customer number;
  vn_total_customers   number;
  vn_cost_per_vat_rate number;
  vn_total_cost_vat    number;
  vn_terms_split_id		 number;
  vn_pre_vat_text      VARCHAR2(250);
  vn_vat_total_text    VARCHAR2(250);
  vn_pre_vat_text_final      VARCHAR2(500);
  vn_vat_total_text_final    VARCHAR2(500);
  vn_vat_total_cost    number;
  vn_loop_counter NUMBER;

--
--CCN13700 start
--
      
CURSOR get_vat_total_amount IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and bc.budget_code = vn_budget_code
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and bc.budget_code = vn_budget_code
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1,vn_expenditure_type2)
       AND BC.BUDGET_CODE = vn_budget_code
       AND 1 = vn_loop_counter
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

  vn_cust_per_vat_rate NUMBER;
  
  CURSOR user_applied_terms_vat IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id)));
     
--CCN06164 End bc/vat rate changes full

--
-- dual offer cursors
-- 

    vn_new_cont_dual NUMBER;
    vn_new_fees_dual NUMBER;
    vn_new_non_cont_dual NUMBER;
    vn_total_cost_dual NUMBER;
    vn_reg_payment_dual NUMBER;
    vn_total_charge_dual NUMBER; 
    vn_vat_rate_dual number;
 --   vn_terms_split_id_dual		 number;     
    
      CURSOR terms_split_id_dual IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;    
    

  	CURSOR budget_category_dual IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;  

  CURSOR get_fees_dual Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

    CURSOR new_costs_dual IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
    select 2, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
 from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid;

  vn_past_code_amount_dual   	NUMBER;     
  CURSOR terms_recovered_asset_dual IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.p2_scheme_version_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID; 
       
--CCN10061 Start bc/vat rate changes dual

  vn_budget_code_dual	     varchar2(3);
  vn_cost_per_bc_dual       number;
  vn_cost_per_customer_dual number;
  vn_total_customers_dual   number;
  vn_cost_per_vat_rate_dual number;
  vn_total_cost_vat_dual    number;
  vn_terms_split_id_dual		 number;
  vn_pre_vat_text_dual      VARCHAR2(250);
  vn_vat_total_text_dual    VARCHAR2(250);
  vn_pre_vat_text_final_dual      VARCHAR2(500);
  vn_vat_total_text_final_dual    VARCHAR2(500);
  vn_vat_total_cost_dual    number;
      
CURSOR get_vat_total_amount_dual IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code_dual
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
    select 2, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
 from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
and SBFM.BUDGET_CODE = BC.BUDGET_CODE
AND bc.budget_code = vn_budget_code_dual
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code_dual
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
       AND BC.BUDGET_CODE = vn_budget_code_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code_dual IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id_dual
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;


  CURSOR user_applied_terms_vat_dual IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_dual)));
         
     
--CCN10061 End bc/vat rate changes dual


                    vn_a_d_fee NUMBER;
                    vn_a_d_fee_vat_total NUMBER;
                    vn_a_d_fee_inc_vat NUMBER;
                    vn_ad_vat_rate NUMBER;

  CURSOR get_a_d_fee IS
    SELECT NVL(SUM(round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',sbfm.fees_cost,sbfm.fees_cost*nvl(ts.CONTINGENCY_AMOUNT,0)/100+sbfm.fees_cost))),0) As "A_D"
      FROM scheme_breakdown_for_margins sbfm, 
           cost_item ci, 
           work_category_for_scheme wcfs,
                         work_category wc,
                         historic_swe hs,
                        (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                           from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                          where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                            and rsi1.CONTINGENCY_IND = 'Y') ts
                  WHERE sbfm.cost_item_id = ci.cost_item_id
                    AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                  AND wcfs.work_category_2(+) = wc.work_category
                    AND sbfm.fees_cost > 0 
                    AND sbfm.description = 'FEES'
                    AND wc.work_category like '%Assessment and Design%'
                    AND ts.scheme_id(+) = sbfm.scheme_id
                    AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                    AND sbfm.standard_work_element_id = hs.standard_work_element_id
                    AND hs.date_to is null
                    AND sbfm.scheme_id = wcfs.scheme_id
                    AND sbfm.scheme_version = wcfs.scheme_version
                    AND sbfm.scheme_id = :PARAMETER.P2_SCHEME_ID
                    AND sbfm.scheme_version = :PARAMETER.P2_SCHEME_VERSION;
                    


    CURSOR get_vat_rate IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id)));


BEGIN
	
--
-- Populate table with costs for main scheme
--



    OPEN terms_split_id;
    FETCH terms_split_id
    INTO vn_terms_split_id;
    CLOSE terms_split_id;

	OPEN budget_category;
	FETCH budget_category
	INTO v2_budget_cat_ind;
	CLOSE budget_category;
	

	
  IF v2_budget_cat_ind IN ('E','N')  THEN
    vn_expenditure_type1 := 226;
    vn_expenditure_type2 := 227;
  ELSE
    vn_expenditure_type1 := 258;
  END IF;  

message('Calculating Costs 10%',NO_ACKNOWLEDGE);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 10%';
  
  IF vn_expenditure_type1 = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:PARAMETER.P2_SCHEME_VERSION,user_pk.get_userid,vn_expenditure_type1);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:PARAMETER.P2_SCHEME_VERSION,user_pk.get_userid);    
  END IF;
 -- commit;
SYNCHRONIZE;
message('Calculating Costs 20%',NO_ACKNOWLEDGE);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 20%';
--
-- get fees
--
    vn_new_cont :=0;
    vn_new_fees :=0;
    vn_new_non_cont :=0;
    vn_total_cost :=0;
    vn_reg_payment :=0;
    vn_total_charge := 0;
  for get_rec IN get_fees LOOP
    vn_new_fees := vn_new_fees+get_rec.fees;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_1 := vn_new_fees;

--
-- CCN13700 start
--
  
  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;

  -- get non-contestable costs
  FOR get_rec IN new_costs LOOP
  	vn_new_cont := vn_new_cont+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont := vn_new_non_cont+get_rec.NONCONTESTABLE_COST;
  END LOOP;
  SYNCHRONIZE;  
  message('Calculating Costs 30%',no_acknowledge);
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 30%';   
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_1 := vn_new_non_cont;
  -- get contestable costs
  SYNCHRONIZE;
  message('Calculating Costs 40%',no_acknowledge);
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 40%';

 :TERMS_CONNECTION_LETTERS_SBK.CONTESTABLE_WORKS_1 := vn_new_cont;

  -- get ECCR payment
  OPEN terms_recovered_asset;
	FETCH terms_recovered_asset
  INTO vn_reg_payment;
	CLOSE terms_recovered_asset;
  SYNCHRONIZE;
  
  message('Calculating Costs 50%',no_acknowledge);
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 50%';	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_1 := vn_reg_payment;
 
  -- get connection charge ex vat
  vn_total_charge := NVL(vn_new_cont,0)+NVL(vn_new_non_cont,0)+NVL(vn_new_fees,0)+NVL(vn_reg_payment,0);  
  SYNCHRONIZE;

  message('Calculating Costs 60%',no_acknowledge);
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 60%';  
	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_1 := vn_total_charge;	
  SYNCHRONIZE;  

  message('Calculating Costs 70%',no_acknowledge);
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 70%';

  -- get vat amount
  DELETE 
    FROM conn_letter_budget_vat
   WHERE scheme_id = :parameter.p2_scheme_id
     AND scheme_version = :parameter.P2_SCHEME_VERSION;
  COMMIT;

  --open cursor to get number of budget codes and loop round for each one
	vn_vat_total_cost := 0;
	vn_total_cost_vat := 0;
	vn_loop_counter := 1;

	vn_total_customers :=0;
  FOR get_rec IN get_budget_code LOOP
  	vn_cost_per_bc := 0;
  	vn_budget_code := NULL;
  	vn_total_customers := NULL;
  	vn_terms_split_id := NULL;
  	
  	vn_budget_code := get_rec.budget_code;
    vn_total_customers := get_rec.number_of_connections;
    vn_terms_split_id := get_rec.terms_split_id;

    --open cursor to get vat_total_amount
    OPEN get_vat_total_amount;
    FETCH get_vat_total_amount
    INTO vn_cost_per_bc;
    CLOSE get_vat_total_amount; 
    
    --if cost is greater then 0 carry on
    IF vn_cost_per_bc >0 THEN
    	
      --use number of connections to divide the vn_total_amount into vn_cost_per_customer    	
      vn_cost_per_customer := round(vn_cost_per_bc/NVL(vn_total_customers,1),2);
      
      --open cursor user_applied_terms_vat to get vat_rate and number of quantity at vat rate and loop      
     	vn_vat_rate := NULL;
     	OPEN user_applied_terms_vat;
     	FETCH user_applied_terms_vat INTO vn_vat_rate;
     	CLOSE user_applied_terms_vat;

      SYNCHRONIZE;
      message('Calculating Costs 80%',no_acknowledge);
      :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 80%';
         	      	      
    END IF;
  END LOOP;
  SYNCHRONIZE;

  message('Calculating Costs 90%',no_acknowledge); 
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 90%';
  :TERMS_CONNECTION_LETTERS_SBK.VAT_1 := round(vn_vat_rate*nvl(vn_total_charge,0),2)/100;
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_1 := round(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_1,0)+vn_total_charge,2);

  OPEN get_vat_rate;
  FETCH get_vat_rate
  INTO vn_ad_vat_rate;
  CLOSE get_vat_rate;

  OPEN get_a_d_fee;
  FETCH get_a_d_fee
  INTO vn_a_d_fee;
  CLOSE get_a_d_fee;
  
  :TERMS_CONNECTION_LETTERS_SBK.OPTION_1_VAT_RATE := vn_ad_vat_rate;
  
  IF vn_a_d_fee >0 THEN 
    vn_a_d_fee_vat_total := vn_a_d_fee*vn_ad_vat_rate/100;
    vn_a_d_fee_inc_vat   := vn_a_d_fee+vn_a_d_fee_vat_total;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_prevat := vn_a_d_fee;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_vat    := vn_a_d_fee_vat_total;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_total  := vn_a_d_fee_inc_vat;
  ELSE  	
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_prevat := 0;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_vat    := 0;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_total  := 0;  	
  END IF;

  SYNCHRONIZE;  
  message('Calculating Costs 100%',no_acknowledge);
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 100%'; 
  
  COMMIT;
	GO_BLOCK('TERMS_CONNECTION_LETTERS_SBK');
	EXECUTE_QUERY;

END;

--- rt_generation_letter\rgl_new_generate_costs.pl ---
PROCEDURE generate_costs IS
		
  vn_alert 				          NUMBER;
  vn_expenditure_type1      NUMBER;
  vn_expenditure_type2      NUMBER;
  vn_expenditure_type1_dual NUMBER;
  vn_expenditure_type2_dual NUMBER;
  v2_budget_cat_ind		      terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  v2_budget_cat_ind_dual		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  vn_new_cont               NUMBER;
  vn_new_non_cont           NUMBER;
  vn_total_cost             NUMBER;
  vn_reg_payment            NUMBER;
  vn_total_charge           NUMBER;
  vn_new_fees               NUMBER;
  vn_vat_rate							  NUMBER;
  vn_a_d_fee                NUMBER;
  vn_a_d_fee_vat_total      NUMBER;
  vn_a_d_fee_inc_vat        NUMBER;
  vn_ad_vat_rate            NUMBER;
  vd_date_of_estimate       DATE;
  v2_quantity               NUMBER(3);
  vn_budget_code	          VARCHAR2(3);
  vn_cost_per_bc            NUMBER;
  vn_cost_per_customer      NUMBER;
  vn_total_customers        NUMBER;
  vn_cost_per_vat_rate      NUMBER;
  vn_total_cost_vat         NUMBER;
  vn_terms_split_id		      NUMBER;
  vn_pre_vat_text           VARCHAR2(250);
  vn_vat_total_text         VARCHAR2(250);
  vn_pre_vat_text_final     VARCHAR2(500);
  vn_vat_total_text_final   VARCHAR2(500);
  vn_vat_total_cost         NUMBER;
  vn_loop_counter           NUMBER;
  vn_cust_per_vat_rate      NUMBER;
  v2_dno                    VARCHAR2(50);


  -- get main costs cursors
  CURSOR c_terms_split_id IS
    SELECT ts.terms_split_id
      FROM terms_budget_code_for_cat bcfc,
           terms_split ts
     WHERE ts.scheme_id = :parameter.p2_scheme_id
       AND ts.scheme_version = :parameter.p2_scheme_version
       AND ts.terms_budget_cat_id = bcfc.terms_budget_cat_id;

	CURSOR c_budget_category IS
	  SELECT budget_category_type_ind
	    FROM terms_budget_cat_for_scheme
	   WHERE scheme_id = :parameter.p2_scheme_id
	     AND scheme_version = :parameter.p2_scheme_version;

  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id
       AND scheme_version = :parameter.p2_scheme_version;

  CURSOR new_costs IS
    SELECT  DISTINCT 
              1,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST,
              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
              nvl(swe.description_for_customer,ci.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,bc.budget_code
       FROM scheme_breakdown_for_margins sbfm,
            cost_item ci,
            cost_item_element cie,
            cost_item_element	non_cont,
            cost_item_element	cont,
            work_category_for_scheme wcfs,
            standard_work_element swe,
            work_category wc,
            work_category_association wca,
            budget_code_for_scheme_split bcfss,
            budget_code bc,
           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
             WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
               AND rsi1.CONTINGENCY_IND = 'Y') ts
      WHERE sbfm.scheme_id = :parameter.p2_scheme_id
        AND sbfm.scheme_version = :parameter.p2_scheme_version
        AND sbfm.userid = user_pk.get_userid
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND ci.cost_item_id = sbfm.cost_item_id
        AND ci.cost_item_indicator != 'T'
        AND cie.cost_item_id = ci.cost_item_id
        AND cie.budget_code IS NULL
        AND swe.standard_work_element_id(+) = ci.standard_work_element_id
        AND bcfss.scheme_id = sbfm.scheme_id
        AND bcfss.scheme_version = sbfm.scheme_version
        AND bc.budget_code = bcfss.budget_code
        AND bc.date_FROM = bcfss.budget_code_date_FROM
        AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
        AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND non_cont.cost_item_id(+) = sbfm.cost_item_id
        AND non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = sbfm.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
        AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
      UNION
     SELECT DISTINCT 
              1,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
              nvl(swe.description_for_customer,ci.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,NULL
       FROM scheme_breakdown_for_margins sbfm,
            cost_item ci,
            work_category_for_scheme wcfs,
            cost_item_element non_cont,
            cost_item_element cont,
            standard_work_element swe,
            work_category_association wca,
            work_category wc,
            cost_item_allocation$v cia,
           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
             WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
               AND rsi1.CONTINGENCY_IND = 'Y') ts
      WHERE sbfm.scheme_id = :parameter.p2_scheme_id
        AND sbfm.scheme_version = :parameter.p2_scheme_version
        AND sbfm.userid = user_pk.get_userid
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND ci.cost_item_id = sbfm.cost_item_id
        AND ci.cost_item_indicator != 'T'
        AND cia.cost_item_id = ci.cost_item_id
        AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
        AND cia.split_indicator = 0
        AND swe.standard_work_element_id(+) = ci.standard_work_element_id
        AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND non_cont.cost_item_id(+) = ci.cost_item_id
        AND non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = ci.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
      UNION
     SELECT DISTINCT 
              1,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
              nvl(swe.description_for_customer,cip.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,null
         FROM scheme_breakdown_for_margins sbfm,
              cost_item ci,
              work_category_for_scheme wcfs,
              cost_item_element non_cont,
              cost_item_element cont,
              standard_work_element swe,
              work_category_association wca,
              work_category wc,
              cost_item_allocation$v cia,
              cost_item cip,
             (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
               WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                 AND rsi1.CONTINGENCY_IND = 'Y') ts
        WHERE sbfm.scheme_id = :parameter.p2_scheme_id
          AND sbfm.scheme_version = :parameter.p2_scheme_version
          AND sbfm.userid = user_pk.get_userid
          AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
          AND ts.scheme_id(+) = sbfm.scheme_id
          AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
          AND cip.cost_item_id = sbfm.cost_item_id
          AND cip.cost_item_indicator != 'T'
          AND ci.parent_cost_item_id = cip.cost_item_id
          AND cia.cost_item_id = ci.cost_item_id
          AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
          AND cia.split_indicator = 0
          AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
          AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
          AND wc.work_category = wcfs.work_category_1
          AND wca.work_category_1(+) = wcfs.work_category_1
          AND wca.work_category_2(+) = wcfs.work_category_2
          AND non_cont.cost_item_id(+) = sbfm.cost_item_id
          AND non_cont.type_of_cost_ri(+) = 206
          AND cont.cost_item_id(+) = sbfm.cost_item_id
          AND cont.type_of_cost_ri(+) = 207
        UNION
       SELECT 2, 
              sum(CONTESTABLE_COST), 
              sum(NONCONTESTABLE_COST), 
              work_cat_desc,total_quantity, 
              'Travel',
              budget_code,work_cat_for_scheme_id, 
              null 
        FROM (SELECT  distinct 
                        2,
                        decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                        decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                        nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                        0 total_quantity,
                        'Travel',
                        bc.budget_code,
                        wcfs.work_cat_for_scheme_id,
                        null
                 FROM travel_cost_for_margins sbfm,
                      work_category_for_scheme wcfs,
                      work_category_association wca,
                      BUDGET_CODE BC,
                      work_category wc,
                      cost_item ci,
                     (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                        FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                       WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                         AND rsi1.CONTINGENCY_IND = 'Y') ts
                WHERE wc.work_category(+) = wcfs.work_category_2
                  AND wca.work_category_1(+) = wcfs.work_category_1
                  AND wca.work_category_2(+) = wcfs.work_category_2
                  AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                  AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                  AND ci.scheme_id = sbfm.scheme_id
                  AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                  AND ci.COST_ITEM_INDICATOR = 'T'
                  AND ts.scheme_id(+) = sbfm.scheme_id
                  AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                  AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                  AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                  AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                  AND sbfm.scheme_id = wcfs.scheme_id
                  AND sbfm.scheme_version = wcfs.scheme_version
                  AND sbfm.scheme_id = :parameter.p2_scheme_id
                  AND sbfm.scheme_version = :parameter.p2_scheme_version
                  AND sbfm.userid = user_pk.get_userid
                UNION
               SELECT distinct 
                        2,
                        round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
                        0 NONCONTESTABLE_COST,
                        nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                        0 total_quantity,
                        'Travel',
                        bc.budget_code,
                        wcfs.work_cat_for_scheme_id,null
                   FROM travel_cost_for_margins sbfm,
                        work_category_for_scheme wcfs,
                        work_category_association wca,
                        BUDGET_CODE BC,
                        work_category wc,
                        cost_item ci,
                        scheme_version sv,
                        budget_code_margin_applicable bcma,
                       (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                          FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                         WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                          AND rsi1.CONTINGENCY_IND = 'Y') ts
                  WHERE wc.work_category(+) = wcfs.work_category_2
                    AND wca.work_category_1(+) = wcfs.work_category_1
                    AND wca.work_category_2(+) = wcfs.work_category_2
                    AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                    AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                    AND ci.scheme_id = sbfm.scheme_id
                    AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                    AND ci.COST_ITEM_INDICATOR = 'T'
                    AND ts.scheme_id(+) = sbfm.scheme_id
                    AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                    AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                    AND sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
                    AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
                    AND sbfm.budget_code = bcma.BUDGET_CODE
                    AND sbfm.budget_code_date_FROM = bcma.BUDGET_CODE_DATE_FROM
                    AND sv.scheme_id = sbfm.scheme_id
                    AND sv.scheme_version = sbfm.scheme_version
                    AND bcma.date_to is null
                    AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                    AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                    AND sbfm.scheme_id = wcfs.scheme_id
                    AND sbfm.scheme_version = wcfs.scheme_version
                    AND sbfm.scheme_id = :parameter.p2_scheme_id
                    AND sbfm.scheme_version = :parameter.p2_scheme_version
                    AND sbfm.userid = user_pk.get_userid)
                  GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  CURSOR terms_recovered_asset IS
    SELECT DISTINCT (NVL(POTENTIAL_REFUND, 0) + NVL(PAST_CODES_AMOUNT, 0)) - NVL(COMM_CREDIT_VALUE, 0)
      FROM terms_split ts,
           budget_code bc,
           terms_budget_code_for_cat tbcfc,
           terms_budget_cat_for_scheme tbcfs
     WHERE tbcfs.scheme_id = :parameter.p2_scheme_id
       AND tbcfs.scheme_version = :parameter.p2_scheme_version
       AND tbcfs.terms_budget_cat_id = tbcfc.terms_budget_cat_id
       AND tbcfc.budget_code = bc.budget_code
       AND tbcfc.budget_code_date_FROM = bc.date_FROM
       AND bc.type_of_expenditure_ri = 258
       AND tbcfs.terms_budget_cat_id = ts.terms_budget_cat_id;

  CURSOR get_fees Is
    SELECT SUM(ROUND(sbfm.fees_cost)) FEES
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           work_category wc,
           historic_swe hs
     WHERE sbfm.cost_item_id = ci.cost_item_id
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       AND wcfs.work_category_2(+) = wc.work_category
       AND sbfm.fees_cost > 0
       AND sbfm.description = 'fees'
       AND sbfm.standard_work_element_id = hs.standard_work_element_id
       AND hs.date_to IS NULL
       AND sbfm.scheme_id = wcfs.scheme_id
       AND sbfm.scheme_version = wcfs.scheme_version
       AND sbfm.scheme_id = :parameter.p2_scheme_id
       AND sbfm.scheme_version = :parameter.p2_scheme_version
       AND sbfm.userid = user_pk.get_userid
     GROUP BY wc.work_category, wc.description_for_customer;

  CURSOR get_vat_total_amount IS
    SELECT SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
     FROM( SELECT DISTINCT 
                    1,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST,
                    nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
                    nvl(swe.description_for_customer,ci.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
             FROM scheme_breakdown_for_margins sbfm,
                  cost_item ci,
                  cost_item_element cie,
                  cost_item_element	non_cont,
                  cost_item_element	cont,
                  work_category_for_scheme wcfs,
                  standard_work_element swe,
                  work_category wc,
                  work_category_association wca,
                  budget_code_for_scheme_split bcfss,
                  budget_code bc,
                 (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                    FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                   WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     AND rsi1.CONTINGENCY_IND = 'Y') ts
            WHERE SBFM.SCHEME_ID = :parameter.p2_scheme_id
              AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
              AND sbfm.userid = user_pk.get_userid
              AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
              AND ts.scheme_id(+) = sbfm.scheme_id
              AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
              AND ci.cost_item_id = sbfm.cost_item_id
              AND ci.cost_item_indicator != 'T'
              AND cie.cost_item_id = ci.cost_item_id
              AND cie.budget_code IS NULL
              AND swe.standard_work_element_id(+) = ci.standard_work_element_id
              AND bcfss.scheme_id = sbfm.scheme_id
              AND bcfss.scheme_version = sbfm.scheme_version
              AND BC.BUDGET_CODE = BCFSS.BUDGET_CODE
              AND bcfss.budget_code = vn_budget_code
              AND bc.date_FROM = bcfss.budget_code_date_FROM
              AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
              AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
              AND wc.work_category = wcfs.work_category_1
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND non_cont.cost_item_id(+) = sbfm.cost_item_id
              AND non_cont.type_of_cost_ri(+) = 206
              AND cont.cost_item_id(+) = sbfm.cost_item_id
              AND cont.type_of_cost_ri(+) = 207
              AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
            UNION
           SELECT DISTINCT 
                    1,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                    nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                    nvl(swe.description_for_customer,ci.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
             FROM scheme_breakdown_for_margins sbfm,
                  cost_item ci,
                  work_category_for_scheme wcfs,
                  cost_item_element cie,
                  cost_item_element non_cont,
                  cost_item_element cont,
                  standard_work_element swe,
                  work_category_association wca,
                  work_category wc,
                  cost_item_allocation$v cia,
                 (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                    FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                   WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     AND rsi1.CONTINGENCY_IND = 'Y') ts
            WHERE sbfm.scheme_id = :parameter.p2_scheme_id
              AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
              AND sbfm.userid = user_pk.get_userid
              AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
              AND ts.scheme_id(+) = sbfm.scheme_id
              AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
              AND ci.cost_item_id = sbfm.cost_item_id
              AND ci.cost_item_indicator != 'T'
              AND CIA.COST_ITEM_ID = CI.COST_ITEM_ID
              AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
              AND cie.budget_code = vn_budget_code
              AND cia.cost_item_id = ci.cost_item_id
              AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
              AND cia.split_indicator = 0
              AND swe.standard_work_element_id(+) = ci.standard_work_element_id
              AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
              AND wc.work_category = wcfs.work_category_1
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND non_cont.cost_item_id(+) = ci.cost_item_id
              AND non_cont.type_of_cost_ri(+) = 206
              AND cont.cost_item_id(+) = ci.cost_item_id
              AND cont.type_of_cost_ri(+) = 207
            UNION
           SELECT DISTINCT 
                    1,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                    nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                    nvl(swe.description_for_customer,cip.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id
             FROM scheme_breakdown_for_margins sbfm,
                  cost_item ci,
                  work_category_for_scheme wcfs,
                  cost_item_element cie,
                  cost_item_element non_cont,
                  cost_item_element cont,
                  standard_work_element swe,
                  work_category_association wca,
                  work_category wc,
                  cost_item_allocation$v cia,
                  cost_item cip,
                 (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                    FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                   WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     AND rsi1.CONTINGENCY_IND = 'Y') ts
            WHERE sbfm.scheme_id = :parameter.p2_scheme_id
              AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
              AND sbfm.userid = user_pk.get_userid
              AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
              AND ts.scheme_id(+) = sbfm.scheme_id
              AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
              AND cip.cost_item_id = sbfm.cost_item_id
              AND cip.cost_item_indicator != 'T'
              AND ci.parent_cost_item_id = cip.cost_item_id
              AND CIA.COST_ITEM_ID = CI.COST_ITEM_ID
              AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
              AND cie.budget_code = vn_budget_code
              AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
              AND cia.split_indicator = 0
              AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
              AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
              AND wc.work_category = wcfs.work_category_1
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND non_cont.cost_item_id(+) = sbfm.cost_item_id
              AND non_cont.type_of_cost_ri(+) = 206
              AND cont.cost_item_id(+) = sbfm.cost_item_id
              AND cont.type_of_cost_ri(+) = 207
            UNION
           SELECT 2,
                  sum(CONTESTABLE_COST), 
                  sum(NONCONTESTABLE_COST), 
                  work_cat_desc, 
                  total_quantity, 
                  'Travel', 
                  budget_code,work_cat_for_scheme_id 
            FROM (SELECT  DISTINCT 
                            2,
                            decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                            decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                            nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                            0 total_quantity,
                            'Travel',
                            bc.budget_code,
                            wcfs.work_cat_for_scheme_id
                     FROM travel_cost_for_margins sbfm,
                          work_category_for_scheme wcfs,
                          work_category_association wca,
                          BUDGET_CODE BC,
                          work_category wc,
                          cost_item ci,
                         (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                            FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                           WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                             AND rsi1.CONTINGENCY_IND = 'Y') ts
                    WHERE wc.work_category(+) = wcfs.work_category_2
                      AND wca.work_category_1(+) = wcfs.work_category_1
                      AND wca.work_category_2(+) = wcfs.work_category_2
                      AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                      AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                      AND ci.scheme_id = sbfm.scheme_id
                      AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                      AND ci.COST_ITEM_INDICATOR = 'T'
                      AND bc.budget_code = vn_budget_code
                      AND ts.scheme_id(+) = sbfm.scheme_id
                      AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                      AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                      AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                      AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                      AND sbfm.scheme_id = wcfs.scheme_id
                      AND sbfm.scheme_version = wcfs.scheme_version
                      AND sbfm.scheme_id = :parameter.p2_scheme_id
                      AND sbfm.scheme_version = :parameter.p2_scheme_version
                      AND sbfm.userid = user_pk.get_userid
                    UNION
                   SELECT DISTINCT 
                            2,
                            round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
                            0 NONCONTESTABLE_COST,
                            nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                            0 total_quantity,
                            'Travel',
                            bc.budget_code,
                            wcfs.work_cat_for_scheme_id
                     FROM travel_cost_for_margins sbfm,
                          work_category_for_scheme wcfs,
                          work_category_association wca,
                          BUDGET_CODE BC,
                          work_category wc,
                          cost_item ci,
                          scheme_version sv,
                          budget_code_margin_applicable bcma,
                         (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                            FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                           WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                             AND rsi1.CONTINGENCY_IND = 'Y') ts
                    WHERE wc.work_category(+) = wcfs.work_category_2
                      AND wca.work_category_1(+) = wcfs.work_category_1
                      AND wca.work_category_2(+) = wcfs.work_category_2
                      AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                      AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                      AND ci.scheme_id = sbfm.scheme_id
                      AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                      AND ci.COST_ITEM_INDICATOR = 'T'
                      AND bc.budget_code = vn_budget_code
                      AND ts.scheme_id(+) = sbfm.scheme_id
                      AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                      AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                      AND sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
                      AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
                      AND sbfm.budget_code = bcma.BUDGET_CODE
                      AND sbfm.budget_code_date_FROM = bcma.BUDGET_CODE_DATE_FROM
                      AND sv.scheme_id = sbfm.scheme_id
                      AND sv.scheme_version = sbfm.scheme_version
                      AND bcma.date_to is null
                      AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
                      AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                      AND sbfm.scheme_id = wcfs.scheme_id
                      AND sbfm.scheme_version = wcfs.scheme_version
                      AND sbfm.scheme_id = :parameter.p2_scheme_id
                      AND sbfm.scheme_version = :parameter.p2_scheme_version
                      AND sbfm.userid = user_pk.get_userid)
                    GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
                    UNION
                   SELECT 2,
                          SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
                          0 NONCONTESTABLE_COST,
                          '0' work_cat_desc,
                          0 total_quantity,
                          'Fees',
                          'Fees',
                          wcfs.work_cat_for_scheme_id
                     FROM scheme_breakdown_for_margins sbfm,
                          COST_ITEM CI,
                          cost_item_element cie,
                          work_category_for_scheme wcfs,
                          work_category wc,
                          historic_swe hs
                    WHERE sbfm.cost_item_id = ci.cost_item_id
                      AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                      AND wcfs.work_category_2(+) = wc.work_category
                      AND sbfm.fees_cost > 0
                      AND SBFM.DESCRIPTION = 'FEES'
                      AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
                      AND cie.budget_code = vn_budget_code
                      AND sbfm.standard_work_element_id = hs.standard_work_element_id
                      AND hs.date_to is null
                      AND sbfm.scheme_id = wcfs.scheme_id
                      AND SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
                      AND SBFM.SCHEME_ID = :parameter.p2_scheme_id
                      AND SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
                      AND sbfm.userid = user_pk.get_userid
                    GROUP BY WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
                    UNION
                   SELECT distinct 
                            2, 
                            (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
                            0 NONCONTESTABLE_COST,
                            '0' work_cat_desc,
                            0 total_quantity,
                            'Refund',
                            'Refund', 
                            0
                     FROM TERMS_SPLIT TS,
                          BUDGET_CODE BC,
                          TERMS_BUDGET_CODE_FOR_CAT TBCFC,
                          TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
                    WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id
                      AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
                      AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
                      AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
                      AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
                      AND BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1,vn_expenditure_type2)
                      AND BC.BUDGET_CODE = vn_budget_code
                      AND 1 = vn_loop_counter
                      AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
                    GROUP BY 1;

  CURSOR get_budget_code IS
    SELECT BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id
      FROM TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     WHERE ts.SCHEME_ID = :parameter.p2_scheme_id
       AND TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

  CURSOR user_applied_terms_vat IS
   SELECT uatgs.quantity, ri.number_field1
     FROM user_appl_terms_gen_stan uatgs,
          crown_owner.reference_item ri
    WHERE ri.reference_item_id = uatgs.vat_type_ri
      AND uatgs.terms_split_id = vn_terms_split_id;

  CURSOR get_a_d_fee IS
    SELECT NVL(SUM(round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',sbfm.fees_cost,sbfm.fees_cost*nvl(ts.CONTINGENCY_AMOUNT,0)/100+sbfm.fees_cost))),0) As "A_D"
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
                         work_category wc,
                         historic_swe hs,
                        (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                           FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                          WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                            AND rsi1.CONTINGENCY_IND = 'Y') ts
                  WHERE sbfm.cost_item_id = ci.cost_item_id
                    AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                    AND wcfs.work_category_2(+) = wc.work_category
                    AND sbfm.fees_cost > 0
                    AND sbfm.description = 'FEES'
                    AND wc.work_category like '%Design%'
                    AND ts.scheme_id(+) = sbfm.scheme_id
                    AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                    AND sbfm.standard_work_element_id = hs.standard_work_element_id
                    AND hs.date_to is null
                    AND sbfm.scheme_id = wcfs.scheme_id
                    AND sbfm.scheme_version = wcfs.scheme_version
                    AND sbfm.userid = user_pk.get_userid
                    AND sbfm.scheme_id = :parameter.p2_scheme_id
                    AND sbfm.scheme_version = :parameter.p2_scheme_version;

  CURSOR get_vat_rate IS
    SELECT quantity
      FROM terms_general_standard
     WHERE terms_general_standard_id IN (SELECT t.terms_general_standard_id
                                           FROM terms_general_standard t
                                          WHERE t.terms_general_standard_id IN (SELECT t.terms_general_standard_id
                                                                                  FROM user_appl_terms_gen_stan u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri = 1339
                                                                                   AND t.date_FROM IS NOT NULL
                                                                                   AND t.date_to IS NULL
                                                                                   AND t.terms_general_standard_id = u.terms_general_standard_id
                                                                                   AND u.terms_split_id(+) = vn_terms_split_id
                                                                                 UNION
                                                                                SELECT t.terms_general_standard_id
                                                                                  FROM user_appl_terms_gen_stan u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri     =1339
                                                                                   AND t.terms_standard_ri =1337
                                                                                   AND t.date_FROM IS NOT NULL
                                                                                   AND t.date_to IS NULL
                                                                                   AND t.terms_general_standard_id = u.terms_general_standard_id(+)
                                                                                   AND u.terms_split_id(+)= vn_terms_split_id
                                                                                   AND NOT EXISTS (SELECT 1 
                                                                                                     FROM USER_APPL_TERMS_GEN_STAN 
                                                                                                    WHERE TERMS_SPLIT_ID = vn_terms_split_id)
                                                                                )
                                        );


BEGIN

  v2_dno := crown_owner.util_scheme_procs.get_dno_for_scheme(:parameter.p2_scheme_id_full, :parameter.p2_scheme_version_full);

  -- Populate table with costs for main scheme
  OPEN c_terms_split_id;
  FETCH c_terms_split_id
  INTO vn_terms_split_id;
  CLOSE c_terms_split_id;

	OPEN c_budget_category;
	FETCH c_budget_category
	INTO v2_budget_cat_ind;
	CLOSE c_budget_category;

  IF v2_budget_cat_ind IN ('E','N')  THEN
    vn_expenditure_type1 := 226;
    vn_expenditure_type2 := 227;
  ELSE
    vn_expenditure_type1 := 258;
  END IF;

  MESSAGE('Calculating Costs 10%',NO_ACKNOWLEDGE);
  :nbt_please_wait_sbk.di_progress  := 'Calculating Costs 10%';

  IF vn_expenditure_type1 = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:parameter.p2_scheme_version,user_pk.get_userid,vn_expenditure_type1);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:parameter.p2_scheme_version,user_pk.get_userid);
  END IF;
 
  SYNCHRONIZE;
  MESSAGE('Calculating Costs 20%',NO_ACKNOWLEDGE);
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 20%';

  -- get fees
  vn_new_cont     := 0;
  vn_new_fees     := 0;
  vn_new_non_cont := 0;
  vn_total_cost   := 0;
  vn_reg_payment  := 0;
  vn_total_charge := 0;

  FOR get_rec IN get_fees LOOP
    vn_new_fees := vn_new_fees+get_rec.fees;
  END LOOP;

  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_1 := vn_new_fees;

  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;

  OPEN get_quantity;
  FETCH get_quantity
  INTO v2_quantity;
  CLOSE get_quantity;

  -- get non-contestable costs
  FOR get_rec IN new_costs LOOP
  	vn_new_cont := vn_new_cont+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont := vn_new_non_cont+get_rec.NONCONTESTABLE_COST;
  END LOOP;
  
  SYNCHRONIZE;
  message('Calculating Costs 30%',no_acknowledge);
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 30%';
  :terms_connection_letters_sbk.non_cont_works_1 := vn_new_non_cont;

  -- get contestable costs
  SYNCHRONIZE;
  message('Calculating Costs 40%',no_acknowledge);  
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 40%';
  :terms_connection_letters_sbk.contestable_works_1 := vn_new_cont;

  -- get ECCR payment
  OPEN terms_recovered_asset;
	FETCH terms_recovered_asset
  INTO vn_reg_payment;
	CLOSE terms_recovered_asset;
  
  SYNCHRONIZE;
  MESSAGE('Calculating Costs 50%',no_acknowledge);
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 50%';
	:terms_connection_letters_sbk.reg_connect_charge_1 := vn_reg_payment;

  -- Get Connection Charge Ex Vat
  vn_total_charge := NVL(vn_new_cont, 0) + NVL(vn_new_non_cont, 0) + NVL(vn_new_fees, 0) + NVL(vn_reg_payment, 0);
  SYNCHRONIZE;
  MESSAGE('Calculating Costs 60%',no_acknowledge);

  :nbt_please_wait_sbk.di_progress:='Calculating Costs 60%';
	:terms_connection_letters_sbk.connection_charge_1 := vn_total_charge;
	SYNCHRONIZE;
  MESSAGE('Calculating Costs 70%',no_acknowledge);

  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 70%';
  
  DELETE 
    FROM conn_letter_budget_vat
   WHERE scheme_id = :parameter.p2_scheme_id
     AND scheme_version = :parameter.p2_scheme_version;
  COMMIT;

  -- Open Cursor To Get Number Of Budget Codes AND Loop Round For Each One
	vn_vat_total_cost   := 0;
	vn_total_cost_vat   := 0;
	vn_loop_counter     := 1;
	vn_total_customers  := 0;

  FOR get_rec IN get_budget_code LOOP
  	vn_cost_per_bc      := 0;
  	vn_budget_code      := NULL;
  	vn_total_customers  := NULL;
  	vn_terms_split_id   := NULL;
  	vn_budget_code      := get_rec.budget_code;
    vn_total_customers  := get_rec.number_of_connections;
    vn_terms_split_id   := get_rec.terms_split_id;

    -- Open Cursor To Get Vat_Total_Amount
    OPEN get_vat_total_amount;
    FETCH get_vat_total_amount
    INTO vn_cost_per_bc;
    CLOSE get_vat_total_amount;

    -- If Cost Is Greater Then 0 Carry On
    IF vn_cost_per_bc > 0 THEN

      -- Use Number Of Connections To Divide The Vn_Total_Amount Into Vn_Cost_Per_Customer
      vn_cost_per_customer := round(vn_cost_per_bc/vn_total_customers,2);
      
      -- Open Cursor User_Applied_Terms_Vat To Get Vat_Rate AND Number Of Quantity At Vat Rate AND Loop      
      FOR get_rec IN user_applied_terms_vat LOOP
      	vn_vat_rate := NULL;
        vn_cust_per_vat_rate := NULL;
        vn_cust_per_vat_rate := get_rec.quantity;
      	vn_vat_rate := get_rec.number_field1;
        
        -- Multiply The Number Of Connections With Vn_Cost_Per_Customer Into Vn_Cust_Per_Vat_Rate
      	vn_cost_per_vat_rate := round(vn_cost_per_customer*vn_cust_per_vat_rate,2);
      	
        -- Multiply Vn_Cost_Per_Vat_Rate With Vat Rate To Get Vn_Total_Cost_Vat Rate
        vn_total_cost_vat := round(vn_vat_rate*vn_cost_per_vat_rate,2)/100;
        
        -- If More Then One Vat Rate Concat Vn_Total
	      IF vn_budget_code = 'RC' THEN
	      	vn_budget_code := 0;
        END IF;

        SYNCHRONIZE;
        message('Calculating Costs 80%',no_acknowledge);
        :nbt_please_wait_sbk.di_progress := 'Calculating Costs 80%';

	      INSERT INTO conn_letter_budget_vat(scheme_id, scheme_version, budget_code, vat_rate, total_cost, vat_total_cost)
	      VALUES(:parameter.p2_scheme_id, :parameter.p2_scheme_version, vn_budget_code, vn_vat_rate, vn_cost_per_vat_rate, vn_total_cost_vat);
	      COMMIT;

        vn_loop_counter := vn_loop_counter + 1;
	      vn_vat_total_cost := vn_vat_total_cost+vn_total_cost_vat;

      END LOOP;
    END IF;
  END LOOP;

  SYNCHRONIZE;
  message('Calculating Costs 90%', no_acknowledge);
  :nbt_please_wait_sbk.di_progress := 'Calculating Costs 90%';
  :terms_connection_letters_sbk.vat_1 := vn_vat_total_cost;

  -- get connection charge inc vat
	:terms_connection_letters_sbk.connect_charge_inc_1 := ROUND(NVL(:terms_connection_letters_sbk.vat_1, 0) + vn_total_charge, 2);

  OPEN get_vat_rate;
  FETCH get_vat_rate
  INTO vn_ad_vat_rate;
  CLOSE get_vat_rate;

  OPEN get_a_d_fee;
  FETCH get_a_d_fee
  INTO vn_a_d_fee;
  CLOSE get_a_d_fee;

  :terms_connection_letters_sbk.option_1_vat_rate := vn_ad_vat_rate;

  IF vn_a_d_fee >0 THEN
    vn_a_d_fee_vat_total := vn_a_d_fee * vn_ad_vat_rate / 100;
    vn_a_d_fee_inc_vat   := vn_a_d_fee + vn_a_d_fee_vat_total;
    :terms_connection_letters_sbk.assessment_design_fees_prevat := vn_a_d_fee;
    :terms_connection_letters_sbk.assessment_design_fees_vat    := vn_a_d_fee_vat_total;
    :terms_connection_letters_sbk.assessment_design_fees_total  := vn_a_d_fee_inc_vat;
  ELSE
    :terms_connection_letters_sbk.assessment_design_fees_prevat := 0;
    :terms_connection_letters_sbk.assessment_design_fees_vat    := 0;
    :terms_connection_letters_sbk.assessment_design_fees_total  := 0;
  END IF;

  SYNCHRONIZE;
  MESSAGE('Calculating Costs 100%',no_acknowledge);
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 100%';

  COMMIT;
	GO_BLOCK('TERMS_CONNECTION_LETTERS_SBK');
	EXECUTE_QUERY;

END;

--- rt_generation_letter\rgl_new_generate_costs_dual.pl ---
PROCEDURE GENERATE_COSTS_DUAL IS
		
  vn_expenditure_type1_dual     NUMBER;
  vn_expenditure_type2_dual     NUMBER;
  vn_vat_dual                   NUMBER;  
  vn_vat_rate_new_dual          NUMBER;
  v2_budget_cat_ind_dual		    terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  vn_new_cont_dual              NUMBER;
  vn_new_fees_dual              NUMBER;
  vn_new_non_cont_dual          NUMBER;
  vn_total_cost_dual            NUMBER;
  vn_reg_payment_dual           NUMBER;
  vn_total_charge_dual          NUMBER; 
  vn_vat_rate_dual              NUMBER;
  vd_date_of_estimate           DATE; 
  vn_budget_code_dual	          VARCHAR2(3);
  vn_cost_per_bc_dual           NUMBER;
  vn_cost_per_customer_dual     NUMBER;
  vn_total_customers_dual       NUMBER;
  vn_cost_per_vat_rate_dual     NUMBER;
  vn_total_cost_vat_dual        NUMBER;
  vn_terms_split_id_dual		    NUMBER;
  vn_pre_vat_text_dual          VARCHAR2(250);
  vn_vat_total_text_dual        VARCHAR2(250);
  vn_pre_vat_text_final_dual    VARCHAR2(500);
  vn_vat_total_text_final_dual  VARCHAR2(500);
  vn_vat_total_cost_dual        NUMBER; 
  vn_loop_counter	              NUMBER;
  v2_dno                        VARCHAR2(50); 
    
  CURSOR terms_split_id_dual IS
    SELECT  ts.terms_split_id 
      FROM  terms_budget_code_for_cat bcfc,
           terms_split ts
     WHERE  ts.scheme_id = :parameter.p2_scheme_id_dual
       AND ts.scheme_version = :parameter.p2_scheme_version_dual
       AND ts.terms_budget_cat_id = bcfc.terms_budget_cat_id;    
    

  CURSOR budget_category_dual IS
	  SELECT  budget_category_type_ind
	    FROM  terms_budget_cat_for_scheme
	   WHERE  scheme_id = :parameter.p2_scheme_id_dual
	     AND scheme_version = :parameter.p2_scheme_version_dual;  

  CURSOR get_fees_dual Is
    SELECT  sum(round(sbfm.fees_cost)) FEES
      FROM  scheme_breakdown_for_margins sbfm, 
           cost_item ci, 
           work_category_for_scheme wcfs,
           work_category wc,
           historic_swe hs
     WHERE  sbfm.cost_item_id = ci.cost_item_id
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       AND wcfs.work_category_2(+) = wc.work_category
       AND sbfm.fees_cost > 0 
       AND sbfm.description = 'FEES'
       AND sbfm.standard_work_element_id = hs.standard_work_element_id
       AND hs.date_to is null
       AND sbfm.scheme_id = wcfs.scheme_id
       AND sbfm.scheme_version = wcfs.scheme_version
       AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
       AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
       AND sbfm.userid = user_pk.get_userid
     GROUP BY wc.work_category, wc.description_for_customer;

  CURSOR get_date_of_estimate IS
    SELECT  DISTINCT date_of_estimate
      FROM  scheme_version
     WHERE  scheme_id = :parameter.p2_scheme_id_dual
       AND scheme_version = :parameter.p2_scheme_version_dual;


  CURSOR terms_recovered_asset_dual IS
    SELECT  DISTINCT (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM  terms_split ts,
           budget_code bc,
           terms_budget_code_for_cat tbcfc,
           terms_budget_cat_for_scheme tbcfs
     WHERE  tbcfs.scheme_id = :parameter.p2_scheme_id_dual
       AND tbcfs.scheme_version = :parameter.p2_scheme_version_dual
       AND tbcfs.terms_budget_cat_id=tbcfc.terms_budget_cat_id
       AND tbcfc.budget_code=bc.budget_code
       AND tbcfc.budget_code_date_from=bc.date_from
       AND bc.type_of_expenditure_ri = 258
       AND tbcfs.terms_budget_cat_id=ts.terms_budget_cat_id; 


  CURSOR new_costs_dual IS
    SELECT   DISTINCT 
              1, 
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
              nvl(swe.description_for_customer,ci.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,bc.budget_code 
       FROM  scheme_breakdown_for_margins sbfm,
            cost_item ci,
            cost_item_element cie,
            cost_item_element	non_cont,
            cost_item_element	cont,
            work_category_for_scheme wcfs,
            standard_work_element swe,
            work_category wc,
            work_category_association wca,
            budget_code_for_scheme_split bcfss,
            budget_code bc,
           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
              FROM  terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
             WHERE  ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
               AND rsi1.CONTINGENCY_IND = 'Y') ts
      WHERE  sbfm.scheme_id = :parameter.p2_scheme_id_dual
        AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
        AND sbfm.userid = user_pk.get_userid
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND ci.cost_item_id = sbfm.cost_item_id
        AND ci.cost_item_indicator != 'T'
        AND cie.cost_item_id = ci.cost_item_id
        AND cie.budget_code IS NULL
        AND swe.standard_work_element_id(+) = ci.standard_work_element_id
        AND bcfss.scheme_id = sbfm.scheme_id
        AND bcfss.scheme_version = sbfm.scheme_version
        AND bc.budget_code = bcfss.budget_code
        AND bc.date_from = bcfss.budget_code_date_from
        AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
        AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND non_cont.cost_item_id(+) = sbfm.cost_item_id
        AND non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = sbfm.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
        AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
      UNION
     SELECT  DISTINCT 
              1, 
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
              nvl(swe.description_for_customer,ci.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,null
       FROM  scheme_breakdown_for_margins sbfm,
            cost_item ci,
            work_category_for_scheme wcfs,
            cost_item_element non_cont,
            cost_item_element cont,
            standard_work_element swe,
            work_category_association wca,
            work_category wc,
            cost_item_allocation$v cia,
           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
              FROM  terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
             WHERE  ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
              AND rsi1.CONTINGENCY_IND = 'Y') ts
      WHERE  sbfm.scheme_id = :parameter.p2_scheme_id_dual
        AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
        AND sbfm.userid = user_pk.get_userid
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND ci.cost_item_id = sbfm.cost_item_id
        AND ci.cost_item_indicator != 'T'
        AND cia.cost_item_id = ci.cost_item_id
        AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
        AND cia.split_indicator = 0
        AND swe.standard_work_element_id(+) = ci.standard_work_element_id
        AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND non_cont.cost_item_id(+) = ci.cost_item_id
        AND non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = ci.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
      UNION
     SELECT  DISTINCT 
              1, 
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
              nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
              NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
              nvl(swe.description_for_customer,cip.description) swe_description,
              sbfm.description,
              sbfm.cost_item_id,null
       FROM  scheme_breakdown_for_margins sbfm,
            cost_item ci,
            work_category_for_scheme wcfs,
            cost_item_element non_cont,
            cost_item_element cont,
            standard_work_element swe,
            work_category_association wca,
            work_category wc,
            cost_item_allocation$v cia,
            cost_item cip,
           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
              FROM  terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
             WHERE  ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
               AND rsi1.CONTINGENCY_IND = 'Y') ts
      WHERE  sbfm.scheme_id = :parameter.p2_scheme_id_dual
        AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
        AND sbfm.userid = user_pk.get_userid
        AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
        AND ts.scheme_id(+) = sbfm.scheme_id
        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
        AND cip.cost_item_id = sbfm.cost_item_id
        AND cip.cost_item_indicator != 'T'
        AND ci.parent_cost_item_id = cip.cost_item_id
        AND cia.cost_item_id = ci.cost_item_id
        AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
        AND cia.split_indicator = 0
        AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
        AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
        AND wc.work_category = wcfs.work_category_1
        AND wca.work_category_1(+) = wcfs.work_category_1
        AND wca.work_category_2(+) = wcfs.work_category_2
        AND non_cont.cost_item_id(+) = sbfm.cost_item_id
        AND non_cont.type_of_cost_ri(+) = 206
        AND cont.cost_item_id(+) = sbfm.cost_item_id
        AND cont.type_of_cost_ri(+) = 207
      UNION
     SELECT  2,
            sum(CONTESTABLE_COST), 
            sum(NONCONTESTABLE_COST),
            work_cat_desc,total_quantity,
            'Travel',
            budget_code,work_cat_for_scheme_id,
            null 
      FROM  ( SELECT  DISTINCT 
                      2, 
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                      decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                      nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                      0 total_quantity,
                      'Travel',
                      bc.budget_code, 
                      wcfs.work_cat_for_scheme_id,null
               FROM  travel_cost_for_margins sbfm,
                    work_category_for_scheme wcfs,
                    work_category_association wca,
                    BUDGET_CODE BC,
                    work_category wc,
                    cost_item ci,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                      FROM  terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                     WHERE  ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts			      
              WHERE  wc.work_category(+) = wcfs.work_category_2
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND ci.scheme_id = sbfm.scheme_id
                AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                AND ci.COST_ITEM_INDICATOR = 'T'
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                AND sbfm.scheme_id = wcfs.scheme_id
                AND sbfm.scheme_version = wcfs.scheme_version
                AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                AND sbfm.userid = user_pk.get_userid   
              UNION
             SELECT  DISTINCT 
                      2, 
                      round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
                      0 NONCONTESTABLE_COST,
                      nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                      0 total_quantity, AND 
                      'Travel',
                      bc.budget_code, 
                      wcfs.work_cat_for_scheme_id,null
               FROM  travel_cost_for_margins sbfm,
                    work_category_for_scheme wcfs,
                    work_category_association wca,
                    BUDGET_CODE BC,
                    work_category wc,
                    cost_item ci,
                    scheme_version sv,
                    budget_code_margin_applicable bcma,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                      FROM  terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                     WHERE  ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts			      
              WHERE  wc.work_category(+) = wcfs.work_category_2
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND ci.scheme_id = sbfm.scheme_id
                AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                AND ci.COST_ITEM_INDICATOR = 'T'
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                AND sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
                AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
                AND sbfm.budget_code = bcma.BUDGET_CODE
                AND sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
                AND sv.scheme_id = sbfm.scheme_id
                AND sv.scheme_version = sbfm.scheme_version
                AND bcma.date_to is null
                AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                AND sbfm.scheme_id = wcfs.scheme_id
                AND sbfm.scheme_version = wcfs.scheme_version
                AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                AND sbfm.userid = user_pk.get_userid)
              GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  

       

  CURSOR get_vat_total_amount_dual IS
    SELECT SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
     FROM (SELECT DISTINCT 
                    1, 
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
                    nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
                    nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
                    NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
                    nvl(swe.description_for_customer,ci.description) swe_description,
                    sbfm.description,
                    sbfm.cost_item_id 
               FROM scheme_breakdown_for_margins sbfm,
                    cost_item ci,
                    cost_item_element cie,
                    cost_item_element	non_cont,
                    cost_item_element	cont,
                    work_category_for_scheme wcfs,
                    standard_work_element swe,
                    work_category wc,
                    work_category_association wca,
                    budget_code_for_scheme_split bcfss,
                    budget_code bc,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                     FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                     WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
                AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
                AND sbfm.userid = user_pk.get_userid
                AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION    
                AND ci.cost_item_id = sbfm.cost_item_id
                AND ci.cost_item_indicator != 'T'
                AND cie.cost_item_id = ci.cost_item_id
                AND cie.budget_code IS NULL
                AND swe.standard_work_element_id(+) = ci.standard_work_element_id
                AND bcfss.scheme_id = sbfm.scheme_id
                AND bcfss.scheme_version = sbfm.scheme_version
                AND BC.BUDGET_CODE = BCFSS.BUDGET_CODE
                AND bcfss.budget_code = vn_budget_code_dual
                AND bc.date_from = bcfss.budget_code_date_from
                AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
                AND wc.work_category = wcfs.work_category_1
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND non_cont.cost_item_id(+) = sbfm.cost_item_id
                AND non_cont.type_of_cost_ri(+) = 206
                AND cont.cost_item_id(+) = sbfm.cost_item_id
                AND cont.type_of_cost_ri(+) = 207
                AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              UNION
             SELECT DISTINCT 
                      1, 
                      nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                      nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                      nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
                      NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                      nvl(swe.description_for_customer,ci.description) swe_description,
                      sbfm.description,
                      sbfm.cost_item_id
               FROM scheme_breakdown_for_margins sbfm,
                    cost_item ci,
                    work_category_for_scheme wcfs,
                    cost_item_element cie,
                    cost_item_element non_cont,
                    cost_item_element cont,
                    standard_work_element swe,
                    work_category_association wca,
                    work_category wc,
                    cost_item_allocation$v cia,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                      FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                     WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
                AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
                AND sbfm.userid = user_pk.get_userid
                AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
                and ts.scheme_id(+) = sbfm.scheme_id
                and ts.scheme_version(+) = sbfm.SCHEME_VERSION
                AND ci.cost_item_id = sbfm.cost_item_id
                AND ci.cost_item_indicator != 'T'
                AND CIA.COST_ITEM_ID = CI.COST_ITEM_ID
                AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
                AND cie.budget_code = vn_budget_code_dual
                AND cia.cost_item_id = ci.cost_item_id
                AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                AND cia.split_indicator = 0
                AND swe.standard_work_element_id(+) = ci.standard_work_element_id
                AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND wc.work_category = wcfs.work_category_1
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND non_cont.cost_item_id(+) = ci.cost_item_id
                AND non_cont.type_of_cost_ri(+) = 206
                AND cont.cost_item_id(+) = ci.cost_item_id
                AND cont.type_of_cost_ri(+) = 207
              UNION
             SELECT DISTINCT 
                      1, 
                      nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
                      nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
                      nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
                      NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
                      nvl(swe.description_for_customer,cip.description) swe_description,
                      sbfm.description,
                      sbfm.cost_item_id
               FROM scheme_breakdown_for_margins sbfm,
                    cost_item ci,
                    work_category_for_scheme wcfs,
                    cost_item_element cie,       
                    cost_item_element non_cont,
                    cost_item_element cont,
                    standard_work_element swe,
                    work_category_association wca,
                    work_category wc,
                    cost_item_allocation$v cia,
                    cost_item cip,
                   (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                      FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                     WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                       AND rsi1.CONTINGENCY_IND = 'Y') ts
              WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
                AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
                AND sbfm.userid = user_pk.get_userid
                AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost >0)
                AND ts.scheme_id(+) = sbfm.scheme_id
                AND ts.scheme_version(+) = sbfm.SCHEME_VERSION    
                AND cip.cost_item_id = sbfm.cost_item_id
                AND cip.cost_item_indicator != 'T'
                AND ci.parent_cost_item_id = cip.cost_item_id
                AND CIA.COST_ITEM_ID = CI.COST_ITEM_ID
                AND CIE.COST_ITEM_ID = CI.COST_ITEM_ID
                AND cie.budget_code = vn_budget_code_dual
                AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                AND cia.split_indicator = 0
                AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
                AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                AND wc.work_category = wcfs.work_category_1
                AND wca.work_category_1(+) = wcfs.work_category_1
                AND wca.work_category_2(+) = wcfs.work_category_2
                AND non_cont.cost_item_id(+) = sbfm.cost_item_id
                AND non_cont.type_of_cost_ri(+) = 206
                AND cont.cost_item_id(+) = sbfm.cost_item_id
                AND cont.type_of_cost_ri(+) = 207
              UNION
             SELECT 2,
                    sum(CONTESTABLE_COST), 
                    sum(NONCONTESTABLE_COST),
                    work_cat_desc,total_quantity, 
                    'Travel',
                    budget_code,work_cat_for_scheme_id 
              FROM ( SELECT DISTINCT 
                              2, 
                              decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                              decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code, 
                              wcfs.work_cat_for_scheme_id
                       FROM travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            BUDGET_CODE BC,
                            work_category wc,
                            cost_item ci,
                           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                             WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                               AND rsi1.CONTINGENCY_IND = 'Y') ts			      
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        AND wca.work_category_1(+) = wcfs.work_category_1
                        AND wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        AND ci.scheme_id = sbfm.scheme_id
                        AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                        AND ci.COST_ITEM_INDICATOR = 'T'
                        AND bc.budget_code = vn_budget_code_dual
                        AND ts.scheme_id(+) = sbfm.scheme_id
                        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                        AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                        AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                        AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND sbfm.scheme_version = wcfs.scheme_version
                        AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                        AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                        AND sbfm.userid = user_pk.get_userid   
                      UNION
                     SELECT DISTINCT 
                              2, 
                              round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
                              0 NONCONTESTABLE_COST,
                              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                              0 total_quantity,
                              'Travel',
                              bc.budget_code, 
                              wcfs.work_cat_for_scheme_id
                       FROM travel_cost_for_margins sbfm,
                            work_category_for_scheme wcfs,
                            work_category_association wca,
                            budget_code bc,
                            work_category wc,
                            cost_item ci,
                            scheme_version sv,
                            budget_code_margin_applicable bcma,
                           (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                              FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                             WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                               AND rsi1.CONTINGENCY_IND = 'Y') ts			      
                      WHERE wc.work_category(+) = wcfs.work_category_2
                        AND wca.work_category_1(+) = wcfs.work_category_1
                        AND wca.work_category_2(+) = wcfs.work_category_2
                        AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
                        AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
                        AND ci.scheme_id = sbfm.scheme_id
                        AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
                        AND ci.COST_ITEM_INDICATOR = 'T'
                        AND bc.budget_code = vn_budget_code_dual
                        AND ts.scheme_id(+) = sbfm.scheme_id
                        AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                        AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
                        AND sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
                        AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
                        AND sbfm.budget_code = bcma.BUDGET_CODE
                        AND sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
                        AND sv.scheme_id = sbfm.scheme_id
                        AND sv.scheme_version = sbfm.scheme_version
                        AND bcma.date_to is null
                        AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                        AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND sbfm.scheme_id = wcfs.scheme_id
                        AND sbfm.scheme_version = wcfs.scheme_version
                        AND sbfm.scheme_id = :parameter.p2_scheme_id_dual
                        AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
                        AND sbfm.userid = user_pk.get_userid)
                      GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
                      UNION
                     SELECT 2,
                            SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
                            0 NONCONTESTABLE_COST,
                            '0' work_cat_desc,
                            0 total_quantity,
                            'Fees',
                            'Fees', 
                            wcfs.work_cat_for_scheme_id
                       FROM scheme_breakdown_for_margins sbfm, 
                            cost_item ci,
                            cost_item_element cie,
                            work_category_for_scheme wcfs,
                            work_category wc,
                            historic_swe hs
                      WHERE sbfm.cost_item_id = ci.cost_item_id
                        and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                        AND wcfs.work_category_2(+) = wc.work_category
                        and sbfm.fees_cost > 0 
                        and SBFM.DESCRIPTION = 'FEES'
                        and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
                        AND cie.budget_code = vn_budget_code_dual
                        and sbfm.standard_work_element_id = hs.standard_work_element_id
                        and hs.date_to is null
                        and sbfm.scheme_id = wcfs.scheme_id
                        and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
                        and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
                        and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
                        and sbfm.userid = user_pk.get_userid
                      GROUP BY WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
                      UNION
                     SELECT DISTINCT 
                              2, 
                              (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
                              0 NONCONTESTABLE_COST,
                              '0' work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
                       FROM TERMS_SPLIT TS,
                            BUDGET_CODE BC,
                            TERMS_BUDGET_CODE_FOR_CAT TBCFC,
                            TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
                       WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
                         AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
                         AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
                         AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
                         AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
                         AND BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
                         AND BC.BUDGET_CODE = vn_budget_code_dual
                         AND 1 = vn_loop_counter
                         AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
                       GROUP BY 1;


  CURSOR get_budget_code_dual IS
    SELECT bcfc.budget_code, ts.number_of_connections,ts.terms_split_id 
      FROM terms_budget_code_for_cat bcfc,
           terms_split ts
     WHERE ts.scheme_id = :parameter.p2_scheme_id_dual
       AND ts.scheme_version = :parameter.p2_scheme_version_dual
       AND ts.terms_budget_cat_id = bcfc.terms_budget_cat_id;


  CURSOR user_applied_terms_vat_dual IS
    SELECT quantity 
      FROM terms_general_standard
     WHERE terms_general_standard_id IN (SELECT t.TERMS_GENERAL_STANDARD_ID 
                                           FROM terms_general_standard t
                                          WHERE t.TERMS_GENERAL_STANDARD_ID IN (SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                  FROM user_appl_terms_gen_stan u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri = 1339
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL 
                                                                                   AND t.terms_general_standard_id = u.terms_general_standard_id
                                                                                   AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
                                                                                 UNION
                                                                                SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                  FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri     =1339
                                                                                   AND t.terms_standard_ri =1337
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL
                                                                                   AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
                                                                                   AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
                                                                                   AND NOT EXISTS (SELECT 1 
                                                                                                     FROM  USER_APPL_TERMS_GEN_STAN 
                                                                                                    WHERE  TERMS_SPLIT_ID = vn_terms_split_id_dual)));


  CURSOR get_vat IS
    SELECT SUM(ROUND(vat_total_cost,2))
      FROM conn_letter_budget_vat
     WHERE scheme_id = :parameter.p2_scheme_id_dual
       AND scheme_version = :parameter.p2_scheme_version_dual;


  CURSOR get_vat_rate_dual IS
    SELECT quantity 
      FROM terms_general_standard
     WHERE terms_general_standard_id IN (SELECT t.TERMS_GENERAL_STANDARD_ID 
                                           FROM terms_general_standard t
                                          WHERE t.TERMS_GENERAL_STANDARD_ID IN (SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                  FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri = 1339
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL 
                                                                                   AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
                                                                                   AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
                                                                                 UNION
                                                                                SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                  FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                 WHERE t.terms_area_ri     = 1339
                                                                                   AND t.terms_standard_ri = 1337
                                                                                   AND t.date_from IS NOT NULL
                                                                                   AND t.date_to IS NULL
                                                                                   AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
                                                                                   AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
                                                                                   AND NOT EXISTS (SELECT 1 
                                                                                                     FROM  USER_APPL_TERMS_GEN_STAN 
                                                                                                    WHERE  TERMS_SPLIT_ID = vn_terms_split_id_dual)));

BEGIN

  v2_dno := crown_owner.util_scheme_procs.get_dno_for_scheme(:parameter.p2_scheme_id_full, :parameter.p2_scheme_version_full);

  OPEN terms_split_id_dual;
  FETCH terms_split_id_dual
  INTO vn_terms_split_id_dual;
  CLOSE terms_split_id_dual;

	OPEN budget_category_dual;
	FETCH budget_category_dual
	INTO v2_budget_cat_ind_dual;
	CLOSE budget_category_dual;
	
  IF v2_budget_cat_ind_dual IN ('E','N')  THEN
    vn_expenditure_type1_dual := 226;
    vn_expenditure_type2_dual := 227;
  ELSE
    vn_expenditure_type1_dual := 258;
  END IF;  

  IF vn_expenditure_type1_dual = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid,vn_expenditure_type1_dual);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid);    
  END IF;

  vn_new_cont_dual :=0;
  vn_new_fees_dual :=0;
  vn_new_non_cont_dual :=0;
  vn_total_cost_dual :=0;
  vn_reg_payment_dual :=0;
  vn_total_charge_dual := 0;
    
  FOR get_rec IN get_fees_dual LOOP
    vn_new_fees_dual := vn_new_fees_dual+get_rec.fees;
  END LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_2 := vn_new_fees_dual;
  
  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
  
  FOR get_rec IN new_costs_dual LOOP
  	vn_new_cont_dual := vn_new_cont_dual+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont_dual := vn_new_non_conT_dual+get_rec.NONCONTESTABLE_COST;
  END LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_2 := vn_new_non_cont_dual;

  -- get ECCR payment
  OPEN terms_recovered_asset_dual;
	FETCH terms_recovered_asset_dual
  INTO vn_reg_payment_dual;
	CLOSE terms_recovered_asset_dual;
	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_2 := vn_reg_payment_dual;
	
  -- get connection charge ex vat
  vn_total_charge_dual := NVL(vn_new_cont_dual,0)+NVL(vn_new_non_cont_dual,0)+NVL(vn_new_fees_dual,0)+NVL(vn_reg_payment_dual,0);

	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_2 := vn_total_charge_dual;

  DELETE 
    FROM  conn_letter_budget_vat
   WHERE  scheme_id = :PARAMETER.P2_SCHEME_ID_dual
     AND scheme_version = :PARAMETER.P2_SCHEME_VERSION_dual;
  COMMIT;

	vn_vat_total_cost_dual := 0;
	vn_total_cost_vat_dual := 0;
  vn_loop_counter := 1;
	vn_total_customers_dual :=0;
	
  FOR get_rec IN get_budget_code_dual LOOP
  	vn_cost_per_bc_dual := 0;
  	vn_budget_code_dual := NULL;
  	vn_total_customers_dual := NULL;
  	vn_terms_split_id_dual := NULL;
  	
  	vn_budget_code_dual := get_rec.budget_code;
    vn_total_customers_dual := get_rec.number_of_connections;
    vn_terms_split_id_dual := get_rec.terms_split_id;

    --open cursor to get vat_total_amount
    OPEN get_vat_total_amount_dual;
    FETCH get_vat_total_amount_dual
    INTO vn_cost_per_bc_dual;
    CLOSE get_vat_total_amount_dual;
    
    -- If Cost Is Greater Then 0 Carry On
    IF vn_cost_per_bc_dual >0 THEN    	

      -- use number of connections to divide the vn_total_amount into vn_cost_per_customer    	
      vn_cost_per_customer_dual := round(vn_cost_per_bc_dual/vn_total_customers_dual,2);
      -- open cursor user_applied_terms_vat to get vat_rate AND number of quantity at vat rate AND loop      
     	OPEN user_applied_terms_vat_dual;
     	FETCH user_applied_terms_vat_dual INTO vn_vat_rate_dual;
     	CLOSE user_applied_terms_vat_dual;

    END IF;
  END LOOP;

  OPEN get_vat;
  FETCH get_vat
  INTO vn_vat_dual;
  CLOSE get_vat;
  
  :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := round(vn_vat_rate_dual*nvl(vn_total_charge_dual,0),2)/100;

  OPEN get_vat_rate_dual;
  FETCH get_vat_rate_dual
  INTO vn_vat_rate_new_dual;
  CLOSE get_vat_rate_dual;
  
  :TERMS_CONNECTION_LETTERS_SBK.OPTION_2_VAT_RATE := vn_vat_rate_new_dual;

	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_2 := round(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_2,0)+vn_total_charge_dual,2);

  COMMIT;
	go_block('TERMS_CONNECTION_LETTERS_SBK');
	execute_query;

END;

--- rt_generation_letter\rgl_old_generate_costs.pl ---
PROCEDURE generate_costs IS
		vn_alert 				NUMBER;
  vn_expenditure_type1 NUMBER;
  vn_expenditure_type2 NUMBER;
  vn_expenditure_type1_dual NUMBER;
  vn_expenditure_type2_dual NUMBER;
  v2_budget_cat_ind		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  v2_budget_cat_ind_dual		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
 -- vn_terms_split_id		 number;  
  vn_new_cont number;
  vn_new_non_cont number;   
  vn_total_cost number; 
  vn_reg_payment NUMBER;
  vn_total_charge NUMBER;
  vn_new_fees NUMBER;
  vn_vat_rate							NUMBER;
  
  
--
-- get main costs cursors
--
  CURSOR terms_split_id IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

    
  CURSOR budget_category IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION;  

--
-- CCN13700 start
--
	     
  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id
       AND scheme_version = :parameter.p2_scheme_version;
     
  vd_date_of_estimate DATE; 
  v2_quantity NUMBER(3);
  
  CURSOR get_quantity IS
  SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
AND trunc(vd_date_of_estimate) BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate)); 	     
	     
	     

    CURSOR new_costs IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,bc.budget_code 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.p2_scheme_version
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,NULL
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.p2_scheme_version
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id,null
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.p2_scheme_version
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id, null FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;


  vn_past_code_amount   	NUMBER;     


  CURSOR terms_recovered_asset IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.P2_SCHEME_ID
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;    

  CURSOR get_fees Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.P2_SCHEME_ID
and sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

--CCN10061 Start bc/vat rate changes full

  vn_budget_code	     varchar2(3);
  vn_cost_per_bc       number;
  vn_cost_per_customer number;
  vn_total_customers   number;
  vn_cost_per_vat_rate number;
  vn_total_cost_vat    number;
  vn_terms_split_id		 number;
  vn_pre_vat_text      VARCHAR2(250);
  vn_vat_total_text    VARCHAR2(250);
  vn_pre_vat_text_final      VARCHAR2(500);
  vn_vat_total_text_final    VARCHAR2(500);
  vn_vat_total_cost    number;
  vn_loop_counter NUMBER;

--
--CCN13700 start
--
      
CURSOR get_vat_total_amount IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and bc.budget_code = vn_budget_code
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and bc.budget_code = vn_budget_code
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1,vn_expenditure_type2)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id
and sbfm.scheme_version = :parameter.p2_scheme_version
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1,vn_expenditure_type2)
       AND BC.BUDGET_CODE = vn_budget_code
       AND 1 = vn_loop_counter
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;

  vn_cust_per_vat_rate NUMBER;
  
  CURSOR user_applied_terms_vat IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id)));
     
--CCN06164 End bc/vat rate changes full

--
-- dual offer cursors
-- 

    vn_new_cont_dual NUMBER;
    vn_new_fees_dual NUMBER;
    vn_new_non_cont_dual NUMBER;
    vn_total_cost_dual NUMBER;
    vn_reg_payment_dual NUMBER;
    vn_total_charge_dual NUMBER; 
    vn_vat_rate_dual number;
 --   vn_terms_split_id_dual		 number;     
    
      CURSOR terms_split_id_dual IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;    
    

  	CURSOR budget_category_dual IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;  

  CURSOR get_fees_dual Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

    CURSOR new_costs_dual IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
    select 2, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
 from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid;

  vn_past_code_amount_dual   	NUMBER;     
  CURSOR terms_recovered_asset_dual IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.p2_scheme_version_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID; 
       
--CCN10061 Start bc/vat rate changes dual

  vn_budget_code_dual	     varchar2(3);
  vn_cost_per_bc_dual       number;
  vn_cost_per_customer_dual number;
  vn_total_customers_dual   number;
  vn_cost_per_vat_rate_dual number;
  vn_total_cost_vat_dual    number;
  vn_terms_split_id_dual		 number;
  vn_pre_vat_text_dual      VARCHAR2(250);
  vn_vat_total_text_dual    VARCHAR2(250);
  vn_pre_vat_text_final_dual      VARCHAR2(500);
  vn_vat_total_text_final_dual    VARCHAR2(500);
  vn_vat_total_cost_dual    number;
      
CURSOR get_vat_total_amount_dual IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code_dual
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
    select 2, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
 from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
and SBFM.BUDGET_CODE = BC.BUDGET_CODE
AND bc.budget_code = vn_budget_code_dual
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code_dual
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
       AND BC.BUDGET_CODE = vn_budget_code_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code_dual IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id_dual
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;


  CURSOR user_applied_terms_vat_dual IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_dual)));
         
     
--CCN10061 End bc/vat rate changes dual


                    vn_a_d_fee NUMBER;
                    vn_a_d_fee_vat_total NUMBER;
                    vn_a_d_fee_inc_vat NUMBER;
                    vn_ad_vat_rate NUMBER;

  CURSOR get_a_d_fee IS
    SELECT NVL(SUM(round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',sbfm.fees_cost,sbfm.fees_cost*nvl(ts.CONTINGENCY_AMOUNT,0)/100+sbfm.fees_cost))),0) As "A_D"
      FROM scheme_breakdown_for_margins sbfm, 
           cost_item ci, 
           work_category_for_scheme wcfs,
                         work_category wc,
                         historic_swe hs,
                        (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
                           from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
                          where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                            and rsi1.CONTINGENCY_IND = 'Y') ts
                  WHERE sbfm.cost_item_id = ci.cost_item_id
                    AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
                  AND wcfs.work_category_2(+) = wc.work_category
                    AND sbfm.fees_cost > 0 
                    AND sbfm.description = 'FEES'
                    AND wc.work_category like '%Assessment and Design%'
                    AND ts.scheme_id(+) = sbfm.scheme_id
                    AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
                    AND sbfm.standard_work_element_id = hs.standard_work_element_id
                    AND hs.date_to is null
                    AND sbfm.scheme_id = wcfs.scheme_id
                    AND sbfm.scheme_version = wcfs.scheme_version
                    AND sbfm.scheme_id = :PARAMETER.P2_SCHEME_ID
                    AND sbfm.scheme_version = :PARAMETER.P2_SCHEME_VERSION;
                    


    CURSOR get_vat_rate IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id)));


BEGIN
	
--
-- Populate table with costs for main scheme
--



    OPEN terms_split_id;
    FETCH terms_split_id
    INTO vn_terms_split_id;
    CLOSE terms_split_id;

	OPEN budget_category;
	FETCH budget_category
	INTO v2_budget_cat_ind;
	CLOSE budget_category;
	

	
  IF v2_budget_cat_ind IN ('E','N')  THEN
    vn_expenditure_type1 := 226;
    vn_expenditure_type2 := 227;
  ELSE
    vn_expenditure_type1 := 258;
  END IF;  

message('Calculating Costs 10%',NO_ACKNOWLEDGE);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 10%';
  
  IF vn_expenditure_type1 = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:PARAMETER.P2_SCHEME_VERSION,user_pk.get_userid,vn_expenditure_type1);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id,:PARAMETER.P2_SCHEME_VERSION,user_pk.get_userid);    
  END IF;
 -- commit;
SYNCHRONIZE;
message('Calculating Costs 20%',NO_ACKNOWLEDGE);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 20%';
--
-- get fees
--
    vn_new_cont :=0;
    vn_new_fees :=0;
    vn_new_non_cont :=0;
    vn_total_cost :=0;
    vn_reg_payment :=0;
    vn_total_charge := 0;
  for get_rec IN get_fees LOOP
    vn_new_fees := vn_new_fees+get_rec.fees;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_1 := vn_new_fees;

--
-- CCN13700 start
--
  
  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
  
  OPEN get_quantity;
  FETCH get_quantity
  INTO v2_quantity;
  CLOSE get_quantity;

--
-- CCN13700 END
--

 
--
-- get non-contestable costs
--
  for get_rec IN new_costs LOOP
  	vn_new_cont := vn_new_cont+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont := vn_new_non_cont+get_rec.NONCONTESTABLE_COST;
  end LOOP;
SYNCHRONIZE;  
message('Calculating Costs 30%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 30%';   
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_1 := vn_new_non_cont;
--
-- get contestable costs
--
SYNCHRONIZE;
message('Calculating Costs 40%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 40%';

 :TERMS_CONNECTION_LETTERS_SBK.CONTESTABLE_WORKS_1 := vn_new_cont;
--
-- get ECCR payment
--
  OPEN terms_recovered_asset;
	FETCH terms_recovered_asset
  INTO vn_reg_payment;
	CLOSE terms_recovered_asset;
SYNCHRONIZE;
message('Calculating Costs 50%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 50%';
	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_1 := vn_reg_payment;


-- 
-- get connection charge ex vat
--
  vn_total_charge := NVL(vn_new_cont,0)+NVL(vn_new_non_cont,0)+NVL(vn_new_fees,0)+NVL(vn_reg_payment,0);
SYNCHRONIZE;
message('Calculating Costs 60%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 60%';  
	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_1 := vn_total_charge;
	SYNCHRONIZE;
message('Calculating Costs 70%',no_acknowledge);
:NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 70%';
--
-- get vat amount
--

--
-- CCN10061 start bc/vat split full
--
  delete from conn_letter_budget_vat
  where scheme_id = :parameter.p2_scheme_id
   and scheme_version = :parameter.P2_SCHEME_VERSION;
  commit;

--open cursor to get number of budget codes and loop round for each one
	vn_vat_total_cost := 0;
	vn_total_cost_vat := 0;
	vn_loop_counter := 1;

	vn_total_customers :=0;
  FOR get_rec IN get_budget_code LOOP
  	vn_cost_per_bc := 0;
  	vn_budget_code := NULL;
  	vn_total_customers := NULL;
  	vn_terms_split_id := NULL;
  	
  	vn_budget_code := get_rec.budget_code;
    vn_total_customers := get_rec.number_of_connections;
    vn_terms_split_id := get_rec.terms_split_id;

--open cursor to get vat_total_amount

    OPEN get_vat_total_amount;
    FETCH get_vat_total_amount
    INTO vn_cost_per_bc;
    CLOSE get_vat_total_amount; 
    
--if cost is greater then 0 carry on
    IF vn_cost_per_bc >0 THEN
    	
--use number of connections to divide the vn_total_amount into vn_cost_per_customer    	
      vn_cost_per_customer := round(vn_cost_per_bc/NVL(vn_total_customers,1),2);
--open cursor user_applied_terms_vat to get vat_rate and number of quantity at vat rate and loop      
 
     	vn_vat_rate := NULL;
     	OPEN user_applied_terms_vat;
     	FETCH user_applied_terms_vat INTO vn_vat_rate;
     	CLOSE user_applied_terms_vat;

      SYNCHRONIZE;
      message('Calculating Costs 80%',no_acknowledge);
      :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 80%';
         	      	      
    END IF;
  END LOOP;
  SYNCHRONIZE;
  message('Calculating Costs 90%',no_acknowledge); 
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 90%';
  --:TERMS_CONNECTION_LETTERS_SBK.VAT_1 := vn_vat_total_cost;
  :TERMS_CONNECTION_LETTERS_SBK.VAT_1 := round(vn_vat_rate*nvl(vn_total_charge,0),2)/100;

--
-- CCN10061 end bc/vat split full
-- 


--
-- get connection charge inc vat
--
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_1 := round(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_1,0)+vn_total_charge,2);


  OPEN get_vat_rate;
  FETCH get_vat_rate
  INTO vn_ad_vat_rate;
  CLOSE get_vat_rate;


  OPEN get_a_d_fee;
  FETCH get_a_d_fee
  INTO vn_a_d_fee;
  CLOSE get_a_d_fee;
  
  :TERMS_CONNECTION_LETTERS_SBK.OPTION_1_VAT_RATE := vn_ad_vat_rate;
  
  IF vn_a_d_fee >0 THEN
  
    vn_a_d_fee_vat_total := vn_a_d_fee*vn_ad_vat_rate/100;
    vn_a_d_fee_inc_vat   := vn_a_d_fee+vn_a_d_fee_vat_total;



    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_prevat := vn_a_d_fee;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_vat    := vn_a_d_fee_vat_total;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_total  := vn_a_d_fee_inc_vat;
  
  ELSE
  	
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_prevat := 0;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_vat    := 0;
    :TERMS_CONNECTION_LETTERS_SBK.Assessment_design_fees_total  := 0;  	
  END IF;
  SYNCHRONIZE;  
  message('Calculating Costs 100%',no_acknowledge);
  :NBT_PLEASE_WAIT_SBK.DI_PROGRESS:='Calculating Costs 100%'; 
  commit;
	go_block('TERMS_CONNECTION_LETTERS_SBK');
	execute_query;

END;

--- rt_generation_letter\rgl_old_generate_costs_dual.pl ---
PROCEDURE GENERATE_COSTS_DUAL IS
		vn_alert 				NUMBER;

  vn_expenditure_type1_dual NUMBER;
  vn_expenditure_type2_dual NUMBER;
  vn_vat_dual NUMBER;

  v2_budget_cat_ind_dual		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;


--
-- dual offer cursors
-- 

    vn_new_cont_dual NUMBER;
    vn_new_fees_dual NUMBER;
    vn_new_non_cont_dual NUMBER;
    vn_total_cost_dual NUMBER;
    vn_reg_payment_dual NUMBER;
    vn_total_charge_dual NUMBER; 
    vn_vat_rate_dual number;
 --   vn_terms_split_id_dual		 number;     
    
      CURSOR terms_split_id_dual IS
    select ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
       and TS.SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;    
    

  	CURSOR budget_category_dual IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
	     AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;  

  CURSOR get_fees_dual Is
       select sum(round(sbfm.fees_cost)) FEES
       from scheme_breakdown_for_margins sbfm, 
     cost_item ci, 
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and sbfm.description = 'FEES'
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid
group by wc.work_category, wc.description_for_customer;

  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :parameter.p2_scheme_id_dual
       AND scheme_version = :parameter.p2_scheme_version_dual;
     
  vd_date_of_estimate DATE; 
  v2_quantity NUMBER(3);
  
  CURSOR get_quantity IS
  SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
AND trunc(vd_date_of_estimate) BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate)); 


    CURSOR new_costs_dual IS
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,bc.budget_code 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   AND bc.budget_code = bcfss.budget_code
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id,null
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id,null
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.p2_scheme_version_dual
   AND sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id,null FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id,null
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  vn_past_code_amount_dual   	NUMBER;     
  CURSOR terms_recovered_asset_dual IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.p2_scheme_version_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI =258
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID; 
       
--CCN10061 Start bc/vat rate changes dual

  vn_budget_code_dual	     varchar2(3);
  vn_cost_per_bc_dual       number;
  vn_cost_per_customer_dual number;
  vn_total_customers_dual   number;
  vn_cost_per_vat_rate_dual number;
  vn_total_cost_vat_dual    number;
  vn_terms_split_id_dual		 number;
  vn_pre_vat_text_dual      VARCHAR2(250);
  vn_vat_total_text_dual    VARCHAR2(250);
  vn_pre_vat_text_final_dual      VARCHAR2(500);
  vn_vat_total_text_final_dual    VARCHAR2(500);
  vn_vat_total_cost_dual    number;
  vn_loop_counter	NUMBER;
      
CURSOR get_vat_total_amount_dual IS
select SUM(CONTESTABLE_COST+NONCONTESTABLE_COST)
FROM(
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id 
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       cost_item_element cie,
       cost_item_element	non_cont,
       cost_item_element	cont,
       work_category_for_scheme wcfs,
       standard_work_element swe,
       work_category wc,
       work_category_association wca,
       budget_code_for_scheme_split bcfss,
       budget_code bc,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 where SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
   AND cie.cost_item_id = ci.cost_item_id
   AND cie.budget_code IS NULL
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND bcfss.scheme_id = sbfm.scheme_id
   AND bcfss.scheme_version = sbfm.scheme_version
   and BC.BUDGET_CODE = BCFSS.BUDGET_CODE
   AND bcfss.budget_code = vn_budget_code_dual
   AND bc.date_from = bcfss.budget_code_date_from
   AND bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
UNION
   SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,ci.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
   AND ci.cost_item_id = sbfm.cost_item_id
   AND ci.cost_item_indicator != 'T'
    and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.cost_item_id = ci.cost_item_id
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = ci.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = ci.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
   UNION
SELECT DISTINCT 1, 
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
nvl(swe.description_for_customer,cip.description) swe_description,
sbfm.description,
sbfm.cost_item_id
  FROM scheme_breakdown_for_margins sbfm,
       cost_item ci,
       work_category_for_scheme wcfs,
       cost_item_element cie,       
       cost_item_element non_cont,
       cost_item_element cont,
       standard_work_element swe,
       work_category_association wca,
       work_category wc,
       cost_item_allocation$v cia,
       cost_item cip,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts
 WHERE sbfm.scheme_id = :parameter.p2_scheme_id_dual
   AND sbfm.scheme_version = :parameter.P2_SCHEME_VERSION_dual
   and sbfm.userid = user_pk.get_userid
   AND (sbfm.contestable_cost > 0 
       OR sbfm.noncontestable_cost >0)
   and ts.scheme_id(+) = sbfm.scheme_id
   and ts.scheme_version(+) = sbfm.SCHEME_VERSION    
   AND cip.cost_item_id = sbfm.cost_item_id
   AND cip.cost_item_indicator != 'T'
   AND ci.parent_cost_item_id = cip.cost_item_id
   and CIA.COST_ITEM_ID = CI.COST_ITEM_ID
   and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
   AND cie.budget_code = vn_budget_code_dual
   AND cia.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
   AND cia.split_indicator = 0
   AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
   AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
   AND wc.work_category = wcfs.work_category_1
   AND wca.work_category_1(+) = wcfs.work_category_1
   AND wca.work_category_2(+) = wcfs.work_category_2
   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
   AND non_cont.type_of_cost_ri(+) = 206
   AND cont.cost_item_id(+) = sbfm.cost_item_id
   AND cont.type_of_cost_ri(+) = 207
UNION
select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
         (select distinct 2, 
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
AND bc.budget_code = vn_budget_code_dual
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid   
UNION
select distinct 2, 
round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*v2_quantity/100,2) CONTESTABLE_COST,
0 NONCONTESTABLE_COST,
nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
0 total_quantity,
'Travel',
bc.budget_code, 
wcfs.work_cat_for_scheme_id
from travel_cost_for_margins sbfm,
      work_category_for_scheme wcfs,
      work_category_association wca,
      BUDGET_CODE BC,
      work_category wc,
      cost_item ci,
      scheme_version sv,
      budget_code_margin_applicable bcma,
     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
        and rsi1.CONTINGENCY_IND = 'Y') ts			      
where wc.work_category(+) = wcfs.work_category_2
and wca.work_category_1(+) = wcfs.work_category_1
and wca.work_category_2(+) = wcfs.work_category_2
AND (sbfm.cont_travel_cost > 0 
OR sbfm.noncont_travel_cost >0)
AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
and ci.scheme_id = sbfm.scheme_id
and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
and ci.COST_ITEM_INDICATOR = 'T'
AND bc.budget_code = vn_budget_code_dual
and ts.scheme_id(+) = sbfm.scheme_id
and ts.scheme_version(+) = sbfm.SCHEME_VERSION
AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
AND sbfm.budget_code = bcma.BUDGET_CODE
and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
and sv.scheme_id = sbfm.scheme_id
and sv.scheme_version = sbfm.scheme_version
and bcma.date_to is null
ANd bc.type_of_expenditure_ri in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
and sbfm.scheme_id = wcfs.scheme_id
and sbfm.scheme_version = wcfs.scheme_version
and sbfm.scheme_id = :parameter.p2_scheme_id_dual
and sbfm.scheme_version = :parameter.p2_scheme_version_dual
and sbfm.userid = user_pk.get_userid)
group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id
union
select 2,SUM(ROUND(SBFM.FEES_COST)) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Fees' ,'Fees', wcfs.work_cat_for_scheme_id
       from scheme_breakdown_for_margins sbfm, 
     COST_ITEM CI,
     cost_item_element cie,
     work_category_for_scheme wcfs,
     work_category wc,
     historic_swe hs
where sbfm.cost_item_id = ci.cost_item_id
and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
AND wcfs.work_category_2(+) = wc.work_category
and sbfm.fees_cost > 0 
and SBFM.DESCRIPTION = 'FEES'
and CIE.COST_ITEM_ID = CI.COST_ITEM_ID
AND cie.budget_code = vn_budget_code_dual
and sbfm.standard_work_element_id = hs.standard_work_element_id
and hs.date_to is null
and sbfm.scheme_id = wcfs.scheme_id
and SBFM.SCHEME_VERSION = WCFS.SCHEME_VERSION
and SBFM.SCHEME_ID = :parameter.p2_scheme_id_dual
and SBFM.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
and sbfm.userid = user_pk.get_userid
group by WCFS.WORK_CATEGORY_1,WCFS.WORK_CATEGORY_2 , WCFS.WORK_CAT_FOR_SCHEME_ID,CIE.BUDGET_CODE
UNION
    select distinct 2, (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0) CONTESTABLE_COST,
       0 NONCONTESTABLE_COST,
      '0'  work_cat_desc,0 total_quantity,'Refund' ,'Refund', 0
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     where TBCFS.SCHEME_ID = :parameter.p2_scheme_id_dual
       AND TBCFS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       and BC.TYPE_OF_EXPENDITURE_RI in (vn_expenditure_type1_dual,vn_expenditure_type2_dual)
       AND BC.BUDGET_CODE = vn_budget_code_dual
       AND 1 = vn_loop_counter
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID)
group by 1;

  CURSOR get_budget_code_dual IS
    select BCFC.BUDGET_CODE, ts.number_of_connections,ts.terms_split_id 
      from TERMS_BUDGET_CODE_FOR_CAT bcfc,
           terms_split ts
     where ts.SCHEME_ID = :parameter.p2_scheme_id_dual
       and TS.SCHEME_VERSION = :parameter.P2_SCHEME_VERSION_dual
       AND ts.terms_budget_cat_id = BCFC.TERMS_BUDGET_CAT_ID;
       
  vn_cust_per_vat_rate_dual NUMBER;

  CURSOR user_applied_terms_vat_dual IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_dual)));
     
     CURSOR get_vat IS
       SELECT sum(ROUND(vat_total_cost,2))
         FROM conn_letter_budget_vat
        WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
          AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;
         
     
--CCN10061 End bc/vat rate changes dual

    vn_vat_rate_new_dual      NUMBER;

    CURSOR get_vat_rate_dual IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_dual
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_dual
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_dual)));


BEGIN

--
-- Populate table with costs for dual offer
--

    OPEN terms_split_id_dual;
    FETCH terms_split_id_dual
    INTO vn_terms_split_id_dual;
    CLOSE terms_split_id_dual;

	OPEN budget_category_dual;
	FETCH budget_category_dual
	INTO v2_budget_cat_ind_dual;
	CLOSE budget_category_dual;
	

	
  IF v2_budget_cat_ind_dual IN ('E','N')  THEN
    vn_expenditure_type1_dual := 226;
    vn_expenditure_type2_dual := 227;
  ELSE
    vn_expenditure_type1_dual := 258;
  END IF;  

--message('calculating dual costs 10%',NO_ACKNOWLEDGE); 

  IF vn_expenditure_type1_dual = 226  THEN
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid,vn_expenditure_type1_dual);
  ELSE
 	  dpcr_report_pk.scheme_breakdown_margins(:parameter.p2_scheme_id_dual,:PARAMETER.P2_SCHEME_VERSION_dual,user_pk.get_userid);    
  END IF;
 -- commit;
  
--SYNCHRONIZE;
--message('calculating dual costs 20%',NO_ACKNOWLEDGE);
--
-- get fees
--
    vn_new_cont_dual :=0;
    vn_new_fees_dual :=0;
    vn_new_non_cont_dual :=0;
    vn_total_cost_dual :=0;
    vn_reg_payment_dual :=0;
    vn_total_charge_dual := 0;
    
  for get_rec IN get_fees_dual LOOP
    vn_new_fees_dual := vn_new_fees_dual+get_rec.fees;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_2 := vn_new_fees_dual;
  
  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
  
  OPEN get_quantity;
  FETCH get_quantity
  INTO v2_quantity;
  CLOSE get_quantity;
  
--  SYNCHRONIZE;
--message('calculating dual costs 30%',NO_ACKNOWLEDGE);
--
-- get non-contestable costs
--
  for get_rec IN new_costs_dual LOOP
  	vn_new_cont_dual := vn_new_cont_dual+get_rec.CONTESTABLE_COST;
  	vn_new_non_cont_dual := vn_new_non_conT_dual+get_rec.NONCONTESTABLE_COST;
  end LOOP;
  
  :TERMS_CONNECTION_LETTERS_SBK.NON_CONT_WORKS_2 := vn_new_non_cont_dual;
--
-- get ECCR payment
--
  OPEN terms_recovered_asset_dual;
	FETCH terms_recovered_asset_dual
  INTO vn_reg_payment_dual;
	CLOSE terms_recovered_asset_dual;
	
	:TERMS_CONNECTION_LETTERS_SBK.REG_CONNECT_CHARGE_2 := vn_reg_payment_dual;
	
-- 
-- get connection charge ex vat
--
  vn_total_charge_dual := NVL(vn_new_cont_dual,0)+NVL(vn_new_non_cont_dual,0)+NVL(vn_new_fees_dual,0)+NVL(vn_reg_payment_dual,0);

	:TERMS_CONNECTION_LETTERS_SBK.CONNECTION_CHARGE_2 := vn_total_charge_dual;
--  SYNCHRONIZE;
--message('calculating dual costs 40%',NO_ACKNOWLEDGE);
--
-- get vat amount
--

--
-- CCN10061 start bc/vat split daul
--

  delete from conn_letter_budget_vat
  where scheme_id = :PARAMETER.P2_SCHEME_ID_dual
    and scheme_version = :PARAMETER.P2_SCHEME_VERSION_dual;
  commit;


--open cursor to get number of budget codes and loop round for each one
	vn_vat_total_cost_dual := 0;
	vn_total_cost_vat_dual := 0;
  vn_loop_counter := 1;
--SYNCHRONIZE;
--message('calculating dual costs 50%',NO_ACKNOWLEDGE);
	vn_total_customers_dual :=0;
	
  FOR get_rec IN get_budget_code_dual LOOP
  	vn_cost_per_bc_dual := 0;
  	vn_budget_code_dual := NULL;
  	vn_total_customers_dual := NULL;
  	vn_terms_split_id_dual := NULL;
  	
  	vn_budget_code_dual := get_rec.budget_code;
    vn_total_customers_dual := get_rec.number_of_connections;
    vn_terms_split_id_dual := get_rec.terms_split_id;

--open cursor to get vat_total_amount

    OPEN get_vat_total_amount_dual;
    FETCH get_vat_total_amount_dual
    INTO vn_cost_per_bc_dual;
    CLOSE get_vat_total_amount_dual;
    
--if cost is greater then 0 carry on
    IF vn_cost_per_bc_dual >0 THEN
    	
--use number of connections to divide the vn_total_amount into vn_cost_per_customer    	
      vn_cost_per_customer_dual := round(vn_cost_per_bc_dual/vn_total_customers_dual,2);
--open cursor user_applied_terms_vat to get vat_rate and number of quantity at vat rate and loop      
     	--vn_terms_split_id_dual := NULL;
     	OPEN user_applied_terms_vat_dual;
     	FETCH user_applied_terms_vat_dual INTO vn_vat_rate_dual;
     	CLOSE user_applied_terms_vat_dual;

    END IF;
  END LOOP;
--SYNCHRONIZE;
--message('calculating dual costs 60%',NO_ACKNOWLEDGE);
      OPEN get_vat;
      FETCH get_vat
      INTO vn_vat_dual;
      CLOSE get_vat;
      
 -- :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := vn_vat_dual;
    
    :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := round(vn_vat_rate_dual*nvl(vn_total_charge_dual,0),2)/100;
    
    /*UPDATE TERMS_CONNECTION_LETTERS
	      SET VAT_2 = vn_vat_dual
	    WHERE SCHEME_ID = :PARAMETER.P2_SCHEME_ID_dual
	      AND SCHEME_VERSION = :PARAMETER.P2_SCHEME_VERSION_dual;*/
	    --COMMIT;
	    --Go_block('TERMS_CONNECTION_LETTERS_SBK');
		  --execute_query;
--SYNCHRONIZE;
--message('calculating dual costs 70%',NO_ACKNOWLEDGE);		  
--
-- CCN10061 end bc/vat split dual
--  
--  :TERMS_CONNECTION_LETTERS_SBK.VAT_2 := vn_vat_dual;
  
  OPEN get_vat_rate_dual;
  FETCH get_vat_rate_dual
  INTO vn_vat_rate_new_dual;
  CLOSE get_vat_rate_dual;
  
  :TERMS_CONNECTION_LETTERS_SBK.OPTION_2_VAT_RATE := vn_vat_rate_new_dual;
--  SYNCHRONIZE;
--message('calculating dual costs 80%',NO_ACKNOWLEDGE);
--
-- get connection charge inc vat
--
--SYNCHRONIZE;
--message('calculating dual costs 80%',NO_ACKNOWLEDGE);
	:TERMS_CONNECTION_LETTERS_SBK.CONNECT_CHARGE_INC_2 := round(nvl(:TERMS_CONNECTION_LETTERS_SBK.VAT_2,0)+vn_total_charge_dual,2);
--SYNCHRONIZE;
--message('calculating dual costs 100%',NO_ACKNOWLEDGE);

  commit;
		go_block('TERMS_CONNECTION_LETTERS_SBK');
		execute_query;

END;

--- rt_project_maintenance\rtpm_new_get_capital_code.pl ---
PROCEDURE get_capital_code IS

  vd_date_of_estimate       DATE;
  vn_sanc_contribution      NUMBER := 0;
  vn_contrib_contribution   NUMBER := 0;
  vn_sanc_cont              NUMBER := 0;
  vn_sanc_non_cont          NUMBER := 0;
  vn_contrib_cont           NUMBER := 0;
  vn_contrib_non_cont       NUMBER := 0;
  vn_fee_amount             NUMBER := 0;
  vn_recovered              NUMBER := 0;
  vn_pr_and_pc              NUMBER := 0;
  vn_new_fees               NUMBER := 0;
  vn_account_no             NUMBER;
  vn_product_code           NUMBER;
  vn_alert                  NUMBER;
  v2_budget_code            VARCHAR2(2);
  vn_margins_quantity       NUMBER(3);
  vn_terms_split_id_full    NUMBER;
  vn_vat_rate_full          NUMBER;
  vn_sanc_amount            NUMBER;
  v2_dno                    VARCHAR2(100); 

  CURSOR cs_capital IS
     SELECT A.budget_code
       FROM budget_code A, budget_code_for_scheme B
      WHERE A.budget_code = B.budget_code
        AND A.date_from = B.budget_code_date_from
        AND B.scheme_id = :project_request_sbk.scheme_id
        AND B.scheme_version = :project_request_sbk.scheme_version
        AND A.type_of_expenditure_ri = 258; 

  CURSOR c_income_codes IS
    SELECT income_product_number, income_product_code
      FROM income_for_scheme_version 
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version
       AND type_of_expenditure_ri IN (258,222)
     ORDER BY income_product_number;

  CURSOR c_budget_code_details (pn_inc_num IN NUMBER, pn_inc_code IN NUMBER) IS
    SELECT icl.budget_code, lpad(icl.ecc,3,'0') ecc, icl.tax_code, bc.date_from
      FROM income_code_lookup icl, budget_code bc
     WHERE icl.account_number = pn_inc_num
       AND icl.product_code = pn_inc_code
       and icl.budget_code = bc.budget_code
       and bc.date_to is null;
       
  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;
     
  CURSOR get_margins_quantity IS
    SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
              AND vd_date_of_estimate BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate));        

  CURSOR c_get_costs(VN_EXP_TYPE IN NUMBER)IS
    SELECT DISTINCT 
            1, 
            ROUND(terms_margin_pk.margin_cost(ci.cost_item_id, sbfm.contestable_cost * NVL(bcfss.percentage_split, 0) / 100), 2) contestable_cost, 
            ROUND(sbfm.noncontestable_cost * NVL(bcfss.percentage_split, 0) / 100, 2)  noncontestable_cost, 
            NVL(wca.description_for_customer, wcfs.work_category_1|| ' '|| wcfs.work_category_2)  work_cat_desc, 
            NVL(cie_non_cont.quantity, 2) + NVL(cont.quantity, 2)  total_quantity, 
            NVL(swe.description_for_customer, ci.description)  swe_description, 
            sbfm.description, 
            sbfm.cost_item_id
     FROM scheme_breakdown_for_margins sbfm, 
          cost_item ci, 
          cost_item_element cie, 
          cost_item_element cie_non_cont, 
          cost_item_element cont, 
          work_category_for_scheme wcfs, 
          standard_work_element swe, 
          work_category wc, 
          work_category_association wca, 
          budget_code_for_scheme_split bcfss, 
          budget_code bc
    WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
      AND sbfm.scheme_version = :project_request_sbk.scheme_version
      AND sbfm.userid = user_pk.get_userid
      AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
      AND ci.cost_item_id = sbfm.cost_item_id
      AND ci.cost_item_indicator != 'T'
      AND cie.cost_item_id = ci.cost_item_id
      AND cie.budget_code IS NULL
      AND swe.standard_work_element_id(+) = ci.standard_work_element_id
      AND bcfss.scheme_id = sbfm.scheme_id
      AND bcfss.scheme_version = sbfm.scheme_version
      AND bc.budget_code = bcfss.budget_code
      AND bc.date_from = bcfss.budget_code_date_from
      AND bc.type_of_expenditure_ri = vn_exp_type
      AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
      AND wc.work_category = wcfs.work_category_1
      AND wca.work_category_1(+) = wcfs.work_category_1
      AND wca.work_category_2(+) = wcfs.work_category_2
      AND cie_non_cont.cost_item_id(+) = sbfm.cost_item_id
      AND cie_non_cont.type_of_cost_ri(+) = 206
      AND cont.cost_item_id(+) = sbfm.cost_item_id
      AND cont.type_of_cost_ri(+) = 207
      AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
    UNION
   SELECT DISTINCT 
            1, 
            ROUND(terms_margin_pk.margin_cost(ci.cost_item_id, sbfm.contestable_cost), 2) contestable_cost, 
            ROUND(sbfm.noncontestable_cost, 2) noncontestable_cost, 
            NVL(wca.description_for_customer, wcfs.work_category_1 || ' ' || wcfs.work_category_2) work_cat_desc, 
            NVL(cie_non_cont.quantity, 2) + NVL(cont.quantity, 2)  total_quantity, 
            NVL(swe.description_for_customer, ci.description)  swe_description, 
            sbfm.description, 
            sbfm.cost_item_id
     FROM scheme_breakdown_for_margins sbfm, cost_item ci, work_category_for_scheme wcfs, cost_item_element cie_non_cont, cost_item_element cont, standard_work_element swe, work_category_association wca, work_category wc, cost_item_allocation$v cia
    WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
      AND sbfm.scheme_version = :project_request_sbk.scheme_version
      AND sbfm.userid = user_pk.get_userid
      AND(sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
      AND ci.cost_item_id = sbfm.cost_item_id
      AND ci.cost_item_indicator != 'T'
      AND cia.cost_item_id = ci.cost_item_id
      AND cia.type_of_expenditure_ri = vn_exp_type
      AND cia.split_indicator = 0
      AND swe.standard_work_element_id(+) = ci.standard_work_element_id
      AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
      AND wc.work_category = wcfs.work_category_1
      AND wca.work_category_1(+) = wcfs.work_category_1
      AND wca.work_category_2(+) = wcfs.work_category_2
      AND cie_non_cont.cost_item_id(+) = ci.cost_item_id
      AND cie_non_cont.type_of_cost_ri(+) = 206
      AND cont.cost_item_id(+) = ci.cost_item_id
      AND cont.type_of_cost_ri(+) = 207
    UNION
   SELECT DISTINCT 
            1, 
            ROUND(terms_margin_pk.margin_cost(cip.cost_item_id, sbfm.contestable_cost), 2) contestable_cost, 
            ROUND(sbfm.noncontestable_cost, 2) noncontestable_cost, 
            NVL(wca.description_for_customer, wcfs.work_category_1|| ' '|| wcfs.work_category_2) work_cat_desc, 
            NVL(cie_non_cont.quantity, 2) + NVL(cont.quantity, 2) total_quantity, 
            NVL(swe.description_for_customer, cip.description) swe_description, 
            sbfm.description, 
            sbfm.cost_item_id
     FROM scheme_breakdown_for_margins sbfm, cost_item ci, work_category_for_scheme wcfs, cost_item_element cie_non_cont, cost_item_element cont, standard_work_element swe, work_category_association wca, work_category wc, cost_item_allocation$v cia, cost_item cip
    WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
      AND sbfm.scheme_version = :project_request_sbk.scheme_version
      AND sbfm.userid = user_pk.get_userid
      AND(sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
      AND cip.cost_item_id = sbfm.cost_item_id
      AND cip.cost_item_indicator != 'T'
      AND ci.parent_cost_item_id = cip.cost_item_id
      AND cia.cost_item_id = ci.cost_item_id
      AND cia.type_of_expenditure_ri = vn_exp_type
      AND cia.split_indicator = 0
      AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
      AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
      AND wc.work_category = wcfs.work_category_1
      AND wca.work_category_1(+) = wcfs.work_category_1
      AND wca.work_category_2(+) = wcfs.work_category_2
      AND cie_non_cont.cost_item_id(+) = sbfm.cost_item_id
      AND cie_non_cont.type_of_cost_ri(+) = 206
      AND cont.cost_item_id(+) = sbfm.cost_item_id
      AND cont.type_of_cost_ri(+) = 207
    UNION
   SELECT DISTINCT 
            2, 
            SUM(contestable_cost), 
            SUM(noncontestable_cost), 
            work_cat_desc, 
            total_quantity, 
            'Travel', 
            budget_code, 
            work_cat_for_scheme_id
     FROM (SELECT DISTINCT 
                    2, 
                    ROUND(sbfm.cont_travel_cost, 2) contestable_cost, 
                    ROUND(sbfm.noncont_travel_cost, 2) noncontestable_cost, 
                    NVL(wca.description_for_customer, wcfs.work_category_1|| ' '|| wcfs.work_category_2) work_cat_desc, 
                    0 total_quantity, 
                    'Travel', 
                    bc.budget_code, 
                    wcfs.work_cat_for_scheme_id
             FROM travel_cost_for_margins sbfm, work_category_for_scheme wcfs, work_category_association wca, budget_code bc, work_category wc
            WHERE wc.work_category(+) = wcfs.work_category_2
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost > 0)
              AND sbfm.budget_code = bc.budget_code
              AND sbfm.budget_code_date_from = bc.date_from
              AND bc.type_of_expenditure_ri = vn_exp_type
              AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND sbfm.scheme_id = wcfs.scheme_id
              AND sbfm.scheme_version = wcfs.scheme_version
              AND sbfm.scheme_id = :project_request_sbk.scheme_id
              AND sbfm.scheme_version = :project_request_sbk.scheme_version
              AND sbfm.userid = user_pk.get_userid
            UNION
           SELECT DISTINCT 
                    2, 
                    ROUND(sbfm.cont_travel_cost * bcma.margin / 100, 2) contestable_cost, 
                    0 noncontestable_cost, 
                    NVL(wca.description_for_customer, wcfs.work_category_1|| ' '|| wcfs.work_category_2) work_cat_desc, 
                    0 total_quantity, 
                    'Travel', 
                    bc.budget_code, 
                    wcfs.work_cat_for_scheme_id
             FROM travel_cost_for_margins sbfm, work_category_for_scheme wcfs, work_category_association wca, budget_code bc, work_category wc, budget_code_margin_applicable bcma
            WHERE wc.work_category(+) = wcfs.work_category_2
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost > 0)
              AND sbfm.budget_code = bc.budget_code
              AND sbfm.budget_code_date_from = bc.date_from
              AND sbfm.engineering_classification = bcma.engineering_classification       
              AND sbfm.budget_code = bcma.budget_code                                     
              AND sbfm.budget_code_date_from = bcma.budget_code_date_from                 
              AND bcma.dno = v2_dno                                                                                          
              AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
              AND bc.type_of_expenditure_ri = vn_exp_type
              AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND sbfm.scheme_id = wcfs.scheme_id
              AND sbfm.scheme_version = wcfs.scheme_version
              AND sbfm.scheme_id = :project_request_sbk.scheme_id
              AND sbfm.scheme_version = :project_request_sbk.scheme_version
              AND sbfm.userid = user_pk.get_userid
          ) 
    GROUP BY work_cat_desc, total_quantity, 'Travel', budget_code, work_cat_for_scheme_id;

  CURSOR c_fee_quantity IS
    SELECT SUM(CIE.QUANTITY) COST_OF_FEE
      FROM COST_ITEM_ELEMENT CIE,
           COST_ITEM         CI
     WHERE CI.SCHEME_ID = :project_request_sbk.scheme_id
       AND CI.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND CI.COST_ITEM_INDICATOR = 'F'
       AND CI.COST_ITEM_ID = CIE.COST_ITEM_ID;

  CURSOR c_comm_credit_value IS
    SELECT COMM_CREDIT_VALUE
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :project_request_sbk.scheme_id
       AND TBCFS.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND TBCFS.TERMS_BUDGET_CAT_ID = TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE = BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
       AND TBCFS.TERMS_BUDGET_CAT_ID = TS.TERMS_BUDGET_CAT_ID;

  CURSOR c_pot_refund_past_codes IS
    SELECT distinct nvl(potential_refund,0)+nvl(past_codes_amount,0) pr_and_pc
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :project_request_sbk.scheme_id
       AND TBCFS.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI IN (258,222)
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;

  CURSOR get_contrib_fees Is
    select SUM(FEES)
      FROM(select sum(round(sbfm.fees_cost)) FEES
             from scheme_breakdown_for_margins sbfm, 
                  cost_item ci, 
                  work_category_for_scheme wcfs,
                  work_category wc,
                  historic_swe hs
            where sbfm.cost_item_id = ci.cost_item_id
              and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND wcfs.work_category_2(+) = wc.work_category
              and sbfm.fees_cost > 0 
              and sbfm.description = 'FEES'
              and sbfm.standard_work_element_id = hs.standard_work_element_id
              and hs.date_to is null
              and sbfm.scheme_id = wcfs.scheme_id
              and sbfm.scheme_version = wcfs.scheme_version
              and sbfm.scheme_id = :project_request_sbk.scheme_id
              and sbfm.scheme_version = :project_request_sbk.scheme_version
              and sbfm.userid = user_pk.get_userid
            group by wc.work_category, wc.description_for_customer);

  CURSOR get_terms_split_id_full IS
    SELECT terms_split_id
      FROM terms_split
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;

  CURSOR c_selected_costs IS
    SELECT sum(cont_cost1)
      FROM selected_costs
     WHERE username = user_pk.get_userid
       AND scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;

BEGIN

  v2_dno := crown_owner.util_scheme_procs.get_dno_for_scheme(:project_request_sbk.scheme_id, :project_request_sbk.scheme_version);

  OPEN cs_capital;
  FETCH cs_capital 
  INTO v2_budget_code;
  IF cs_capital%NOTFOUND THEN
    NULL;
  ELSE
    OPEN c_income_codes;
    FETCH c_income_codes 
    INTO vn_account_no, vn_product_code;
    CLOSE c_income_codes;

    IF vn_account_no IS NOT NULL AND vn_product_code IS NOT NULL THEN
  	  Go_Block('project_request_budget_mbk');
      Last_Record;
      Next_Record;

  	  :project_request_budget_mbk.account_number      := vn_account_no;
  	  :project_request_budget_mbk.product_code        := vn_product_code;
      :project_request_budget_mbk.project_request_id  := :project_request_sbk.project_request_id;
      :project_request_budget_mbk.managed_unit        := :project_request_sbk.managed_unit;
      :project_request_budget_mbk.capital_code_ind    := 'C';
  
      OPEN c_budget_code_details(:project_request_budget_mbk.account_number, :project_request_budget_mbk.product_code);
      FETCH c_budget_code_details INTO 
            :project_request_budget_mbk.budget_code, 
            :project_request_budget_mbk.engineering_classification, 
            :project_request_budget_mbk.tax_code, 
            :project_request_budget_mbk.budget_code_date_from;
      
      IF c_budget_code_details%FOUND THEN
        CLOSE c_budget_code_details;
  
        dpcr_report_pk.scheme_breakdown_margins(:project_request_sbk.scheme_id, :project_request_sbk.scheme_version, user_pk.get_userid);
 
        OPEN get_date_of_estimate;
        FETCH get_date_of_estimate
        INTO vd_date_of_estimate;
        CLOSE get_date_of_estimate;
  
        OPEN get_margins_quantity;
        FETCH get_margins_quantity
        INTO vn_margins_quantity;
        CLOSE get_margins_quantity;
 
        FOR c_get_costs_rec IN c_get_costs(222) LOOP
          vn_sanc_cont := vn_sanc_cont + c_get_costs_rec.CONTESTABLE_COST;
          vn_sanc_non_cont := vn_sanc_non_cont + c_get_costs_rec.NONCONTESTABLE_COST;
        END LOOP;
 
        FOR c_get_costs_rec IN c_get_costs(258) LOOP
          vn_sanc_cont := vn_sanc_cont + c_get_costs_rec.CONTESTABLE_COST;
          vn_sanc_non_cont := vn_sanc_non_cont + c_get_costs_rec.NONCONTESTABLE_COST;
          vn_contrib_cont := vn_contrib_cont + c_get_costs_rec.CONTESTABLE_COST;
          vn_contrib_non_cont := vn_contrib_non_cont + c_get_costs_rec.NONCONTESTABLE_COST;
        END LOOP;
      
        OPEN c_selected_costs;
        FETCH c_selected_costs INTO vn_sanc_amount;
        CLOSE c_selected_costs;

        OPEN c_fee_quantity;
        FETCH c_fee_quantity INTO vn_fee_amount;
        CLOSE c_fee_quantity;
  
        OPEN c_comm_credit_value;
        FETCH c_comm_credit_value INTO vn_recovered;
        CLOSE c_comm_credit_value;
    
        OPEN c_pot_refund_past_codes;
        FETCH c_pot_refund_past_codes INTO vn_pr_and_pc;
        CLOSE c_pot_refund_past_codes;

        OPEN get_contrib_fees;
        FETCH get_contrib_fees INTO vn_new_fees;
        CLOSE get_contrib_fees;
      
        IF vn_new_fees IS NULL THEN 
        	
          Set_Application_Property(cursor_style,'Default');
          Hide_View('PLEASE_WAIT_2');

          Set_Alert_Property('STOP_YES_NO', Alert_Message_Text, 'No FEES have been included on this scheme version.  Please confirm that you wish to continue project request.');
          vn_alert := Show_Alert('STOP_YES_NO');

          IF vn_alert = Alert_Button2 THEN
            exit_form(NO_VALIDATE);
          else
            vn_new_fees := 0;
          END IF;
        END IF;

        OPEN get_terms_split_id_full;
        FETCH get_terms_split_id_full INTO vn_terms_split_id_full;
        CLOSE get_terms_split_id_full;
      
        vn_sanc_contribution    := vn_sanc_cont + vn_sanc_non_cont;
        vn_contrib_contribution := vn_contrib_cont + vn_contrib_non_cont + vn_new_fees + vn_pr_and_pc;
        vn_contrib_contribution := round(vn_contrib_contribution,2) * -1;
        synchronize;

        IF vn_contrib_contribution is null THEN
          Set_Application_Property(cursor_style,'Default');
          Hide_View('PLEASE_WAIT_2');
  	      alert_stop_ok('Error calculating contribution, please check costs for null values.');
          exit_form(NO_VALIDATE);
        END IF;

        :project_request_budget_mbk.budget_code_sanction_amount := vn_contrib_contribution;
        :project_budget_control_sbk.di_contribution := vn_contrib_contribution;

      ELSE --c_budget_code_details not found
        CLOSE c_budget_code_details;
        Set_Application_Property(cursor_style,'Default');
        Hide_View('PLEASE_WAIT_2');
  	    alert_stop_ok('Invalid income code combination.  Please review and amend project summary.');
        exit_form(NO_VALIDATE);
      END IF;
    ELSE --c_income_codes not found
	    Set_Application_Property(cursor_style,'Default');
      Hide_View('PLEASE_WAIT_2');
  	  alert_stop_ok('No capital code found, please generate project summary to create capital code.');
      exit_form(NO_VALIDATE);
    END IF;
  END IF;  
  CLOSE cs_capital;

  Go_Block('project_request_budget_mbk');
  First_Record;
END;

--- rt_project_maintenance\rtpm_old_get_capital_code.pl ---
PROCEDURE get_capital_code IS

  vn_sanc_contribution    NUMBER := 0;
  vn_contrib_contribution NUMBER := 0;
  vn_sanc_cont            NUMBER := 0;
  vn_sanc_non_cont        NUMBER := 0;
  vn_contrib_cont         NUMBER := 0;
  vn_contrib_non_cont     NUMBER := 0;
  vn_fee_amount           NUMBER := 0;
  vn_recovered            NUMBER := 0;
  vn_pr_and_pc            NUMBER := 0;
  vn_new_fees							NUMBER := 0;
  vn_account_no           NUMBER;
  vn_product_code         NUMBER;
  vn_alert                NUMBER;
  v2_budget_code          VARCHAR2(2);
  vn_terms_split_id_full  NUMBER;
  vn_vat_rate_full        NUMBER;
  vn_sanc_amount          NUMBER;

  CURSOR cs_capital IS
     SELECT A.budget_code
       FROM budget_code A, budget_code_for_scheme B
      WHERE A.budget_code = B.budget_code
        AND A.date_from = B.budget_code_date_from
        AND B.scheme_id = :project_request_sbk.scheme_id
        AND B.scheme_version = :project_request_sbk.scheme_version
        AND A.type_of_expenditure_ri = 258; 

  CURSOR c1 IS
    SELECT income_product_number, income_product_code
      FROM income_for_scheme_version 
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version
       AND type_of_expenditure_ri IN (258,222)
     ORDER BY income_product_number;

  CURSOR c2 (pn_inc_num IN NUMBER, pn_inc_code IN NUMBER) IS
    SELECT icl.budget_code, lpad(icl.ecc,3,'0') ecc, icl.tax_code, bc.date_from
      FROM income_code_lookup icl, budget_code bc
     WHERE icl.account_number = pn_inc_num
       AND icl.product_code = pn_inc_code
       and icl.budget_code = bc.budget_code
       and bc.date_to is null;
       
--
-- CCN13700 start
--
	     
  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;
     
  vd_date_of_estimate DATE; 
  vn_margins_quantity NUMBER(3);
  
  CURSOR get_margins_quantity IS
    SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
              AND vd_date_of_estimate BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate));        

  CURSOR c3 (vn_exp_type IN NUMBER)IS
    SELECT DISTINCT 1, round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*nvl(bcfss.percentage_split,0)/100 ),2) CONTESTABLE_COST,
           round(sbfm.NONcontestable_cost*nvl(bcfss.percentage_split,0)/100,2) NONCONTESTABLE_COST, 
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,NVL(NON_CONT.QUANTITY,2)+NVL(CONT.QUANTITY,2)  total_quantity,
           nvl(swe.description_for_customer,ci.description) swe_description,sbfm.description,sbfm.cost_item_id 
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           cost_item_element cie,
           cost_item_element non_cont,
           cost_item_element cont,
           work_category_for_scheme wcfs,
           standard_work_element swe,
           work_category wc,
           work_category_association wca,
           budget_code_for_scheme_split bcfss,
           budget_code bc
     WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
       AND sbfm.scheme_version = :project_request_sbk.scheme_version
       AND sbfm.userid = user_pk.get_userid
       AND (sbfm.contestable_cost > 0 
        OR sbfm.noncontestable_cost >0)
       AND ci.cost_item_id = sbfm.cost_item_id
       AND ci.cost_item_indicator != 'T'
       AND cie.cost_item_id = ci.cost_item_id
       AND cie.budget_code IS NULL
       AND swe.standard_work_element_id(+) = ci.standard_work_element_id
       AND bcfss.scheme_id = sbfm.scheme_id
       AND bcfss.scheme_version = sbfm.scheme_version
       AND bc.budget_code = bcfss.budget_code
       AND bc.date_from = bcfss.budget_code_date_from
       AND bc.type_of_expenditure_ri = vn_exp_type
       AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
       AND wc.work_category = wcfs.work_category_1
       AND wca.work_category_1(+) = wcfs.work_category_1
       AND wca.work_category_2(+) = wcfs.work_category_2
       AND non_cont.cost_item_id(+) = sbfm.cost_item_id
       AND non_cont.type_of_cost_ri(+) = 206
       AND cont.cost_item_id(+) = sbfm.cost_item_id
       AND cont.type_of_cost_ri(+) = 207
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
     UNION
    SELECT DISTINCT 1, round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2) CONTESTABLE_COST,
           round(sbfm.NONcontestable_cost,2) NONCONTESTABLE_COST,
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, NVL(NON_CONT.QUANTITY,2)+NVL(CONT.QUANTITY,2) total_quantity,
           nvl(swe.description_for_customer,ci.description) swe_description,sbfm.description,sbfm.cost_item_id
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           cost_item_element non_cont,
           cost_item_element cont,
           standard_work_element swe,
           work_category_association wca,
           work_category wc,
           cost_item_allocation$v cia
     WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
       AND sbfm.scheme_version = :project_request_sbk.scheme_version
       AND sbfm.userid = user_pk.get_userid
       AND (sbfm.contestable_cost > 0 
        OR sbfm.noncontestable_cost >0)
       AND ci.cost_item_id = sbfm.cost_item_id
       AND ci.cost_item_indicator != 'T'
       AND cia.cost_item_id = ci.cost_item_id
       AND cia.type_of_expenditure_ri = vn_exp_type
       AND cia.split_indicator = 0
       AND swe.standard_work_element_id(+) = ci.standard_work_element_id
       AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
       AND wc.work_category = wcfs.work_category_1
       AND wca.work_category_1(+) = wcfs.work_category_1
       AND wca.work_category_2(+) = wcfs.work_category_2
       AND non_cont.cost_item_id(+) = ci.cost_item_id
       AND non_cont.type_of_cost_ri(+) = 206
       AND cont.cost_item_id(+) = ci.cost_item_id
       AND cont.type_of_cost_ri(+) = 207
     UNION
    SELECT DISTINCT 1, round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2) CONTESTABLE_COST,
           round(sbfm.NONcontestable_cost,2) NONCONTESTABLE_COST,
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
           NVL(NON_CONT.QUANTITY,2)+NVL(CONT.QUANTITY,2) total_quantity,
           nvl(swe.description_for_customer,cip.description) swe_description,
           sbfm.description,
           sbfm.cost_item_id
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           cost_item_element non_cont,
           cost_item_element cont,
           standard_work_element swe,
           work_category_association wca,
           work_category wc,
           cost_item_allocation$v cia,
           cost_item cip
     WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
       AND sbfm.scheme_version = :project_request_sbk.scheme_version
       AND sbfm.userid = user_pk.get_userid
       AND (sbfm.contestable_cost > 0 
        OR sbfm.noncontestable_cost >0)
       AND cip.cost_item_id = sbfm.cost_item_id
       AND cip.cost_item_indicator != 'T'
       AND ci.parent_cost_item_id = cip.cost_item_id
       AND cia.cost_item_id = ci.cost_item_id
       AND cia.type_of_expenditure_ri = vn_exp_type
       AND cia.split_indicator = 0
       AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
       AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
       AND wc.work_category = wcfs.work_category_1
       AND wca.work_category_1(+) = wcfs.work_category_1
       AND wca.work_category_2(+) = wcfs.work_category_2
       AND non_cont.cost_item_id(+) = sbfm.cost_item_id
       AND non_cont.type_of_cost_ri(+) = 206
       AND cont.cost_item_id(+) = sbfm.cost_item_id
       AND cont.type_of_cost_ri(+) = 207
     UNION
  select distinct 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
  (select distinct 2, round(sbfm.cont_travel_cost,2) CONTESTABLE_COST,
           round(sbfm.noncont_travel_cost,2) NONCONTESTABLE_COST,
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
           0 total_quantity,
           'Travel',
           bc.budget_code, 
           wcfs.work_cat_for_scheme_id
      from travel_cost_for_margins sbfm,
           work_category_for_scheme wcfs,
           work_category_association wca,
           BUDGET_CODE BC,
           work_category wc
     where wc.work_category(+) = wcfs.work_category_2
       and wca.work_category_1(+) = wcfs.work_category_1
       and wca.work_category_2(+) = wcfs.work_category_2
       AND (sbfm.cont_travel_cost > 0 
        OR sbfm.noncont_travel_cost >0)
       AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
       AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
       ANd bc.type_of_expenditure_ri = vn_exp_type
       and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       and sbfm.scheme_id = wcfs.scheme_id
       and sbfm.scheme_version = wcfs.scheme_version
       and sbfm.scheme_id = :project_request_sbk.scheme_id
       and sbfm.scheme_version = :project_request_sbk.scheme_version
       AND sbfm.userid = user_pk.get_userid
   UNION
    select distinct 2, round(sbfm.cont_travel_cost*vn_margins_quantity/100,2) CONTESTABLE_COST,
              0 NONCONTESTABLE_COST,
              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
              0 total_quantity,
              'Travel',
              bc.budget_code, 
              wcfs.work_cat_for_scheme_id
         from travel_cost_for_margins sbfm,
              work_category_for_scheme wcfs,
              work_category_association wca,
              BUDGET_CODE BC,
              work_category wc,
              budget_code_margin_applicable bcma
        where wc.work_category(+) = wcfs.work_category_2
          and wca.work_category_1(+) = wcfs.work_category_1
          and wca.work_category_2(+) = wcfs.work_category_2
          AND (sbfm.cont_travel_cost > 0 
           OR sbfm.noncont_travel_cost >0)
          AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
          AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
          and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
          AND sbfm.budget_code = bcma.BUDGET_CODE
          and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
          ANd bc.type_of_expenditure_ri = vn_exp_type
          and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
          and sbfm.scheme_id = wcfs.scheme_id
          and sbfm.scheme_version = wcfs.scheme_version
          and sbfm.scheme_id = :project_request_sbk.scheme_id
          and sbfm.scheme_version = :project_request_sbk.scheme_version
          AND sbfm.userid = user_pk.get_userid)
        group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  CURSOR c4 IS
    SELECT SUM(CIE.QUANTITY) COST_OF_FEE
      FROM COST_ITEM_ELEMENT CIE,
           COST_ITEM         CI
     WHERE CI.SCHEME_ID = :project_request_sbk.scheme_id
       AND CI.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND CI.COST_ITEM_INDICATOR = 'F'
       AND CI.COST_ITEM_ID = CIE.COST_ITEM_ID;

  CURSOR c5 IS
    SELECT COMM_CREDIT_VALUE
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :project_request_sbk.scheme_id
       AND TBCFS.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND TBCFS.TERMS_BUDGET_CAT_ID = TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE = BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
       AND TBCFS.TERMS_BUDGET_CAT_ID = TS.TERMS_BUDGET_CAT_ID;

  CURSOR c6 IS
    SELECT distinct nvl(potential_refund,0)+nvl(past_codes_amount,0) pr_and_pc
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :project_request_sbk.scheme_id
       AND TBCFS.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI IN (258,222)
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;

  CURSOR get_contrib_fees Is
    select SUM(FEES)
      FROM(select sum(round(sbfm.fees_cost)) FEES
             from scheme_breakdown_for_margins sbfm, 
                  cost_item ci, 
                  work_category_for_scheme wcfs,
                  work_category wc,
                  historic_swe hs
            where sbfm.cost_item_id = ci.cost_item_id
              and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND wcfs.work_category_2(+) = wc.work_category
              and sbfm.fees_cost > 0 
              and sbfm.description = 'FEES'
              and sbfm.standard_work_element_id = hs.standard_work_element_id
              and hs.date_to is null
              and sbfm.scheme_id = wcfs.scheme_id
              and sbfm.scheme_version = wcfs.scheme_version
              and sbfm.scheme_id = :project_request_sbk.scheme_id
              and sbfm.scheme_version = :project_request_sbk.scheme_version
              and sbfm.userid = user_pk.get_userid
            group by wc.work_category, wc.description_for_customer);

  CURSOR get_terms_split_id_full IS
    SELECT terms_split_id
      FROM terms_split
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;

--  CURSOR get_vat_rate_full IS
--    SELECT quantity
--    FROM terms_general_standard
--   WHERE terms_general_standard_id = 
-- (SELECT t.TERMS_GENERAL_STANDARD_ID 
--    FROM terms_general_standard t
--   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
-- (SELECT t.TERMS_GENERAL_STANDARD_ID
--    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
--   WHERE t.terms_area_ri = 1339
--     AND t.date_from IS NOT NULL
--     AND t.date_to IS NULL 
--     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
--     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_full
--   UNION
--  SELECT t.TERMS_GENERAL_STANDARD_ID
--    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
--   WHERE t.terms_area_ri     =1339
--     AND t.terms_standard_ri =1337
--     AND t.date_from IS NOT NULL
--     AND t.date_to IS NULL
--     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
--     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_full
--     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_full)));

  CURSOR c7 IS
    SELECT sum(cont_cost1)
      FROM selected_costs
     WHERE username = user_pk.get_userid
       AND scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;

BEGIN

  OPEN cs_capital;
  FETCH cs_capital INTO v2_budget_code;
  IF cs_capital%NOTFOUND THEN

    null;

  ELSE

    OPEN c1;
    FETCH c1 INTO vn_account_no, vn_product_code;
    CLOSE c1;

    IF vn_account_no IS NOT NULL AND vn_product_code IS NOT NULL THEN
  	
      Go_Block('project_request_budget_mbk');
      Last_Record;
      Next_Record;

  	  :project_request_budget_mbk.account_number := vn_account_no;
  	  :project_request_budget_mbk.product_code := vn_product_code;

      :project_request_budget_mbk.project_request_id := :project_request_sbk.project_request_id;
      :project_request_budget_mbk.managed_unit := :project_request_sbk.managed_unit;
--      :project_request_budget_mbk.budget_code_date_from := sysdate;
      :project_request_budget_mbk.capital_code_ind := 'C';
  
      OPEN c2(:project_request_budget_mbk.account_number, :project_request_budget_mbk.product_code);
      FETCH c2 INTO :project_request_budget_mbk.budget_code, :project_request_budget_mbk.engineering_classification, 
                    :project_request_budget_mbk.tax_code, :project_request_budget_mbk.budget_code_date_from;
      IF c2%FOUND THEN

        CLOSE c2;
  
        dpcr_report_pk.scheme_breakdown_margins(:project_request_sbk.scheme_id, :project_request_sbk.scheme_version, user_pk.get_userid);
 
        OPEN get_date_of_estimate;
        FETCH get_date_of_estimate
        INTO vd_date_of_estimate;
        CLOSE get_date_of_estimate;
  
        OPEN get_margins_quantity;
        FETCH get_margins_quantity
        INTO vn_margins_quantity;
        CLOSE get_margins_quantity;
 
  
        FOR c3_rec IN c3(222) LOOP
          vn_sanc_cont := vn_sanc_cont + c3_rec.CONTESTABLE_COST;
          vn_sanc_non_cont := vn_sanc_non_cont + c3_rec.NONCONTESTABLE_COST;
        END LOOP;
 
        FOR c3_rec IN c3(258) LOOP
          vn_sanc_cont := vn_sanc_cont + c3_rec.CONTESTABLE_COST;
          vn_sanc_non_cont := vn_sanc_non_cont + c3_rec.NONCONTESTABLE_COST;

          vn_contrib_cont := vn_contrib_cont + c3_rec.CONTESTABLE_COST;
          vn_contrib_non_cont := vn_contrib_non_cont + c3_rec.NONCONTESTABLE_COST;
        END LOOP;
      
        OPEN c7;
        FETCH c7 INTO vn_sanc_amount;
        CLOSE c7;

        OPEN c4;
        FETCH c4 INTO vn_fee_amount;
        CLOSE c4;
  
        OPEN c5;
        FETCH c5 INTO vn_recovered;
        CLOSE c5;
    
        OPEN c6;
        FETCH c6 INTO vn_pr_and_pc;
        CLOSE c6;

        OPEN get_contrib_fees;
        FETCH get_contrib_fees INTO vn_new_fees;
        CLOSE get_contrib_fees;
      
        if vn_new_fees is null then 
        	
          Set_Application_Property(cursor_style,'Default');
          Hide_View('PLEASE_WAIT_2');

          Set_Alert_Property('STOP_YES_NO', Alert_Message_Text, 'No FEES have been included on this scheme version.  Please confirm that you wish to continue project request.');
          vn_alert := Show_Alert('STOP_YES_NO');

          IF vn_alert = Alert_Button2 THEN

            exit_form(NO_VALIDATE);

          else

            vn_new_fees := 0;

          end if;

        end if;

        OPEN get_terms_split_id_full;
        FETCH get_terms_split_id_full INTO vn_terms_split_id_full;
        CLOSE get_terms_split_id_full;
      
--      IF vn_terms_split_id_full IS NOT NULL THEN
--      	OPEN get_vat_rate_full;
--      	FETCH get_vat_rate_full INTO vn_vat_rate_full;
--      	CLOSE get_vat_rate_full;
--      END IF;

        vn_sanc_contribution := vn_sanc_cont + vn_sanc_non_cont;

        vn_contrib_contribution := vn_contrib_cont + vn_contrib_non_cont + vn_new_fees + vn_pr_and_pc;

        vn_contrib_contribution := round(vn_contrib_contribution,2) * -1;

        synchronize;

        IF vn_contrib_contribution is null THEN
          Set_Application_Property(cursor_style,'Default');
          Hide_View('PLEASE_WAIT_2');
  	      alert_stop_ok('Error calculating contribution, please check costs for null values.');
          exit_form(NO_VALIDATE);
        END IF;

      --:project_request_budget_mbk.budget_code_sanction_amount := vn_sanc_contribution;
        :project_request_budget_mbk.budget_code_sanction_amount := vn_contrib_contribution;
        :project_budget_control_sbk.di_contribution := vn_contrib_contribution;

      else --c2 not found

        CLOSE c2;
        Set_Application_Property(cursor_style,'Default');
        Hide_View('PLEASE_WAIT_2');
  	    alert_stop_ok('Invalid income code combination.  Please review and amend project summary.');
        exit_form(NO_VALIDATE);

      end if;

    else --c1 not found
	
--  IF NOT crown_owner.project_financial_approval_pk.capital_code_found(:project_request_sbk.scheme_id,:project_request_sbk.scheme_version) THEN
      Set_Application_Property(cursor_style,'Default');
      Hide_View('PLEASE_WAIT_2');
  	  alert_stop_ok('No capital code found, please generate project summary to create capital code.');
      exit_form(NO_VALIDATE);
--  END IF;


    END IF;

  END IF;  
  CLOSE cs_capital;

  Go_Block('project_request_budget_mbk');
  First_Record;

END;

--- rt_project_raise\rtpr_new_get_capital_code.pl ---
PROCEDURE get_capital_code IS

  vd_date_of_estimate       DATE;
  vn_sanc_contribution      NUMBER := 0;
  vn_contrib_contribution   NUMBER := 0;
  vn_sanc_cont              NUMBER := 0;
  vn_sanc_non_cont          NUMBER := 0;
  vn_contrib_cont           NUMBER := 0;
  vn_contrib_non_cont       NUMBER := 0;
  vn_fee_amount             NUMBER := 0;
  vn_recovered              NUMBER := 0;
  vn_pr_and_pc              NUMBER := 0;
  vn_new_fees               NUMBER := 0;
  vn_account_no             NUMBER;
  vn_product_code           NUMBER;
  vn_alert                  NUMBER;
  v2_budget_code            VARCHAR2(2);
  vn_margins_quantity       NUMBER(3);
  vn_terms_split_id_full    NUMBER;
  vn_vat_rate_full          NUMBER;
  vn_sanc_amount            NUMBER;
  v2_dno                    VARCHAR2(100); 

  CURSOR cs_capital IS
     SELECT A.budget_code
       FROM budget_code A, budget_code_for_scheme B
      WHERE A.budget_code = B.budget_code
        AND A.date_from = B.budget_code_date_from
        AND B.scheme_id = :project_request_sbk.scheme_id
        AND B.scheme_version = :project_request_sbk.scheme_version
        AND A.type_of_expenditure_ri = 258; 

  CURSOR c_income_codes IS
    SELECT income_product_number, income_product_code
      FROM income_for_scheme_version 
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version
       AND type_of_expenditure_ri IN (258,222)
     ORDER BY income_product_number;

  CURSOR c_budget_code_details (pn_inc_num IN NUMBER, pn_inc_code IN NUMBER) IS
    SELECT icl.budget_code, lpad(icl.ecc,3,'0') ecc, icl.tax_code, bc.date_from
      FROM income_code_lookup icl, budget_code bc
     WHERE icl.account_number = pn_inc_num
       AND icl.product_code = pn_inc_code
       and icl.budget_code = bc.budget_code
       and bc.date_to is null;
  
  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;

  CURSOR get_margins_quantity IS
    SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
              AND vd_date_of_estimate BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate));        


  CURSOR c_get_costs(VN_EXP_TYPE IN NUMBER)IS
    SELECT DISTINCT 
            1, 
            ROUND(terms_margin_pk.margin_cost(ci.cost_item_id, sbfm.contestable_cost * NVL(bcfss.percentage_split, 0) / 100), 2) contestable_cost, 
            ROUND(sbfm.noncontestable_cost * NVL(bcfss.percentage_split, 0) / 100, 2)  noncontestable_cost, 
            NVL(wca.description_for_customer, wcfs.work_category_1|| ' '|| wcfs.work_category_2)  work_cat_desc, 
            NVL(cie_non_cont.quantity, 2) + NVL(cont.quantity, 2)  total_quantity, 
            NVL(swe.description_for_customer, ci.description)  swe_description, 
            sbfm.description, 
            sbfm.cost_item_id
     FROM scheme_breakdown_for_margins sbfm, 
          cost_item ci, 
          cost_item_element cie, 
          cost_item_element cie_non_cont, 
          cost_item_element cont, 
          work_category_for_scheme wcfs, 
          standard_work_element swe, 
          work_category wc, 
          work_category_association wca, 
          budget_code_for_scheme_split bcfss, 
          budget_code bc
    WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
      AND sbfm.scheme_version = :project_request_sbk.scheme_version
      AND sbfm.userid = user_pk.get_userid
      AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
      AND ci.cost_item_id = sbfm.cost_item_id
      AND ci.cost_item_indicator != 'T'
      AND cie.cost_item_id = ci.cost_item_id
      AND cie.budget_code IS NULL
      AND swe.standard_work_element_id(+) = ci.standard_work_element_id
      AND bcfss.scheme_id = sbfm.scheme_id
      AND bcfss.scheme_version = sbfm.scheme_version
      AND bc.budget_code = bcfss.budget_code
      AND bc.date_from = bcfss.budget_code_date_from
      AND bc.type_of_expenditure_ri = vn_exp_type
      AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
      AND wc.work_category = wcfs.work_category_1
      AND wca.work_category_1(+) = wcfs.work_category_1
      AND wca.work_category_2(+) = wcfs.work_category_2
      AND cie_non_cont.cost_item_id(+) = sbfm.cost_item_id
      AND cie_non_cont.type_of_cost_ri(+) = 206
      AND cont.cost_item_id(+) = sbfm.cost_item_id
      AND cont.type_of_cost_ri(+) = 207
      AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
    UNION
   SELECT DISTINCT 
            1, 
            ROUND(terms_margin_pk.margin_cost(ci.cost_item_id, sbfm.contestable_cost), 2) contestable_cost, 
            ROUND(sbfm.noncontestable_cost, 2) noncontestable_cost, 
            NVL(wca.description_for_customer, wcfs.work_category_1 || ' ' || wcfs.work_category_2) work_cat_desc, 
            NVL(cie_non_cont.quantity, 2) + NVL(cont.quantity, 2)  total_quantity, 
            NVL(swe.description_for_customer, ci.description)  swe_description, 
            sbfm.description, 
            sbfm.cost_item_id
     FROM scheme_breakdown_for_margins sbfm, cost_item ci, work_category_for_scheme wcfs, cost_item_element cie_non_cont, cost_item_element cont, standard_work_element swe, work_category_association wca, work_category wc, cost_item_allocation$v cia
    WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
      AND sbfm.scheme_version = :project_request_sbk.scheme_version
      AND sbfm.userid = user_pk.get_userid
      AND(sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
      AND ci.cost_item_id = sbfm.cost_item_id
      AND ci.cost_item_indicator != 'T'
      AND cia.cost_item_id = ci.cost_item_id
      AND cia.type_of_expenditure_ri = vn_exp_type
      AND cia.split_indicator = 0
      AND swe.standard_work_element_id(+) = ci.standard_work_element_id
      AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
      AND wc.work_category = wcfs.work_category_1
      AND wca.work_category_1(+) = wcfs.work_category_1
      AND wca.work_category_2(+) = wcfs.work_category_2
      AND cie_non_cont.cost_item_id(+) = ci.cost_item_id
      AND cie_non_cont.type_of_cost_ri(+) = 206
      AND cont.cost_item_id(+) = ci.cost_item_id
      AND cont.type_of_cost_ri(+) = 207
    UNION
   SELECT DISTINCT 
            1, 
            ROUND(terms_margin_pk.margin_cost(cip.cost_item_id, sbfm.contestable_cost), 2) contestable_cost, 
            ROUND(sbfm.noncontestable_cost, 2) noncontestable_cost, 
            NVL(wca.description_for_customer, wcfs.work_category_1|| ' '|| wcfs.work_category_2) work_cat_desc, 
            NVL(cie_non_cont.quantity, 2) + NVL(cont.quantity, 2) total_quantity, 
            NVL(swe.description_for_customer, cip.description) swe_description, 
            sbfm.description, 
            sbfm.cost_item_id
     FROM scheme_breakdown_for_margins sbfm, cost_item ci, work_category_for_scheme wcfs, cost_item_element cie_non_cont, cost_item_element cont, standard_work_element swe, work_category_association wca, work_category wc, cost_item_allocation$v cia, cost_item cip
    WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
      AND sbfm.scheme_version = :project_request_sbk.scheme_version
      AND sbfm.userid = user_pk.get_userid
      AND(sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
      AND cip.cost_item_id = sbfm.cost_item_id
      AND cip.cost_item_indicator != 'T'
      AND ci.parent_cost_item_id = cip.cost_item_id
      AND cia.cost_item_id = ci.cost_item_id
      AND cia.type_of_expenditure_ri = vn_exp_type
      AND cia.split_indicator = 0
      AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
      AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
      AND wc.work_category = wcfs.work_category_1
      AND wca.work_category_1(+) = wcfs.work_category_1
      AND wca.work_category_2(+) = wcfs.work_category_2
      AND cie_non_cont.cost_item_id(+) = sbfm.cost_item_id
      AND cie_non_cont.type_of_cost_ri(+) = 206
      AND cont.cost_item_id(+) = sbfm.cost_item_id
      AND cont.type_of_cost_ri(+) = 207
    UNION
   SELECT DISTINCT 
            2, 
            SUM(contestable_cost), 
            SUM(noncontestable_cost), 
            work_cat_desc, 
            total_quantity, 
            'Travel', 
            budget_code, 
            work_cat_for_scheme_id
     FROM (SELECT DISTINCT 
                    2, 
                    ROUND(sbfm.cont_travel_cost, 2) contestable_cost, 
                    ROUND(sbfm.noncont_travel_cost, 2) noncontestable_cost, 
                    NVL(wca.description_for_customer, wcfs.work_category_1|| ' '|| wcfs.work_category_2) work_cat_desc, 
                    0 total_quantity, 
                    'Travel', 
                    bc.budget_code, 
                    wcfs.work_cat_for_scheme_id
             FROM travel_cost_for_margins sbfm, work_category_for_scheme wcfs, work_category_association wca, budget_code bc, work_category wc
            WHERE wc.work_category(+) = wcfs.work_category_2
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost > 0)
              AND sbfm.budget_code = bc.budget_code
              AND sbfm.budget_code_date_from = bc.date_from
              AND bc.type_of_expenditure_ri = vn_exp_type
              AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND sbfm.scheme_id = wcfs.scheme_id
              AND sbfm.scheme_version = wcfs.scheme_version
              AND sbfm.scheme_id = :project_request_sbk.scheme_id
              AND sbfm.scheme_version = :project_request_sbk.scheme_version
              AND sbfm.userid = user_pk.get_userid
            UNION
           SELECT DISTINCT 
                    2, 
                    ROUND(sbfm.cont_travel_cost * bcma.margin / 100, 2) contestable_cost, 
                    0 noncontestable_cost, 
                    NVL(wca.description_for_customer, wcfs.work_category_1|| ' '|| wcfs.work_category_2) work_cat_desc, 
                    0 total_quantity, 
                    'Travel', 
                    bc.budget_code, 
                    wcfs.work_cat_for_scheme_id
             FROM travel_cost_for_margins sbfm, work_category_for_scheme wcfs, work_category_association wca, budget_code bc, work_category wc, budget_code_margin_applicable bcma
            WHERE wc.work_category(+) = wcfs.work_category_2
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost > 0)
              AND sbfm.budget_code = bc.budget_code
              AND sbfm.budget_code_date_from = bc.date_from
              AND sbfm.engineering_classification = bcma.engineering_classification       
              AND sbfm.budget_code = bcma.budget_code                                     
              AND sbfm.budget_code_date_from = bcma.budget_code_date_from                 
              AND bcma.dno = v2_dno                                                                                          
              AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
              AND bc.type_of_expenditure_ri = vn_exp_type
              AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND sbfm.scheme_id = wcfs.scheme_id
              AND sbfm.scheme_version = wcfs.scheme_version
              AND sbfm.scheme_id = :project_request_sbk.scheme_id
              AND sbfm.scheme_version = :project_request_sbk.scheme_version
              AND sbfm.userid = user_pk.get_userid
          ) 
    GROUP BY work_cat_desc, total_quantity, 'Travel', budget_code, work_cat_for_scheme_id;


  CURSOR c_fee_quantity IS
    SELECT SUM(CIE.QUANTITY) COST_OF_FEE
      FROM COST_ITEM_ELEMENT CIE,
           COST_ITEM         CI
     WHERE CI.SCHEME_ID = :project_request_sbk.scheme_id
       AND CI.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND CI.COST_ITEM_INDICATOR = 'F'
       AND CI.COST_ITEM_ID = CIE.COST_ITEM_ID;

  CURSOR c_comm_credit_value IS
    SELECT COMM_CREDIT_VALUE
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :project_request_sbk.scheme_id
       AND TBCFS.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND TBCFS.TERMS_BUDGET_CAT_ID = TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE = BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
       AND TBCFS.TERMS_BUDGET_CAT_ID = TS.TERMS_BUDGET_CAT_ID;

  CURSOR c_pot_refund_past_codes IS
    SELECT distinct nvl(potential_refund,0)+nvl(past_codes_amount,0) pr_and_pc
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :project_request_sbk.scheme_id
       AND TBCFS.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI IN (258,222)
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;

  CURSOR get_contrib_fees Is
    select SUM(FEES)
      FROM(select sum(round(sbfm.fees_cost)) FEES
             from scheme_breakdown_for_margins sbfm, 
                  cost_item ci, 
                  work_category_for_scheme wcfs,
                  work_category wc,
                  historic_swe hs
            where sbfm.cost_item_id = ci.cost_item_id
              and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND wcfs.work_category_2(+) = wc.work_category
              and sbfm.fees_cost > 0 
              and sbfm.description = 'FEES'
              and sbfm.standard_work_element_id = hs.standard_work_element_id
              and hs.date_to is null
              and sbfm.scheme_id = wcfs.scheme_id
              and sbfm.scheme_version = wcfs.scheme_version
              and sbfm.scheme_id = :project_request_sbk.scheme_id
              and sbfm.scheme_version = :project_request_sbk.scheme_version
              and sbfm.userid = user_pk.get_userid
            group by wc.work_category, wc.description_for_customer);

  CURSOR get_terms_split_id_full IS
    SELECT terms_split_id
      FROM terms_split
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;

  CURSOR c_selected_costs IS
    SELECT sum(cont_cost1)
      FROM selected_costs
     WHERE username = user_pk.get_userid
       AND scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;

BEGIN

  v2_dno := crown_owner.util_scheme_procs.get_dno_for_scheme(:project_request_sbk.scheme_id, :project_request_sbk.scheme_version);

  OPEN cs_capital;
  FETCH cs_capital INTO v2_budget_code;
  IF cs_capital%NOTFOUND THEN
    NULL;
  ELSE
    OPEN c_income_codes;
    FETCH c_income_codes 
    INTO vn_account_no, vn_product_code;
    CLOSE c_income_codes;

    IF vn_account_no IS NOT NULL AND vn_product_code IS NOT NULL THEN
  	
      Go_Block('project_request_budget_mbk');
      Last_Record;
      Next_Record;

  	  :project_request_budget_mbk.account_number      := vn_account_no;
  	  :project_request_budget_mbk.product_code        := vn_product_code;
      :project_request_budget_mbk.project_request_id  := :project_request_sbk.project_request_id;
      :project_request_budget_mbk.managed_unit        := :project_request_sbk.managed_unit;
      :project_request_budget_mbk.capital_code_ind    := 'C';
  
      OPEN c_budget_code_details(:project_request_budget_mbk.account_number, :project_request_budget_mbk.product_code);
      FETCH c_budget_code_details 
      INTO  :project_request_budget_mbk.budget_code, 
            :project_request_budget_mbk.engineering_classification, 
            :project_request_budget_mbk.tax_code, 
            :project_request_budget_mbk.budget_code_date_from;
      
      IF c_budget_code_details%FOUND THEN
        CLOSE c_budget_code_details;
  
        dpcr_report_pk.scheme_breakdown_margins(:project_request_sbk.scheme_id, :project_request_sbk.scheme_version, user_pk.get_userid);
 
        OPEN get_date_of_estimate;
        FETCH get_date_of_estimate
        INTO vd_date_of_estimate;
        CLOSE get_date_of_estimate;
  
        OPEN get_margins_quantity;
        FETCH get_margins_quantity
        INTO vn_margins_quantity;
        CLOSE get_margins_quantity;
   
        FOR c_get_costs_rec IN c_get_costs(222) LOOP
          vn_sanc_cont := vn_sanc_cont + c_get_costs_rec.CONTESTABLE_COST;
          vn_sanc_non_cont := vn_sanc_non_cont + c_get_costs_rec.NONCONTESTABLE_COST;
        END LOOP;
 
        FOR c_get_costs_rec IN c_get_costs(258) LOOP
          vn_sanc_cont        := vn_sanc_cont + c_get_costs_rec.CONTESTABLE_COST;
          vn_sanc_non_cont    := vn_sanc_non_cont + c_get_costs_rec.NONCONTESTABLE_COST;
          vn_contrib_cont     := vn_contrib_cont + c_get_costs_rec.CONTESTABLE_COST;
          vn_contrib_non_cont := vn_contrib_non_cont + c_get_costs_rec.NONCONTESTABLE_COST;
        END LOOP;
      
        OPEN c_selected_costs;
        FETCH c_selected_costs INTO vn_sanc_amount;
        CLOSE c_selected_costs;

        OPEN c_fee_quantity;
        FETCH c_fee_quantity INTO vn_fee_amount;
        CLOSE c_fee_quantity;
  
        OPEN c_comm_credit_value;
        FETCH c_comm_credit_value INTO vn_recovered;
        CLOSE c_comm_credit_value;
    
        OPEN c_pot_refund_past_codes;
        FETCH c_pot_refund_past_codes INTO vn_pr_and_pc;
        CLOSE c_pot_refund_past_codes;

        OPEN get_contrib_fees;
        FETCH get_contrib_fees INTO vn_new_fees;
        CLOSE get_contrib_fees;
      
        IF vn_new_fees is null THEN         	
          Set_Application_Property(cursor_style,'Default');
          Hide_View('PLEASE_WAIT_2');

          Set_Alert_Property('STOP_YES_NO', Alert_Message_Text, 'No FEES have been included on this scheme version.  Please confirm that you wish to continue project request.');
          vn_alert := Show_Alert('STOP_YES_NO');

          IF vn_alert = Alert_Button2 THEN
            exit_form(NO_VALIDATE);
          ELSE
            vn_new_fees := 0;
          END IF;
        END IF;

        OPEN get_terms_split_id_full;
        FETCH get_terms_split_id_full INTO vn_terms_split_id_full;
        CLOSE get_terms_split_id_full;
      
        vn_sanc_contribution    := vn_sanc_cont + vn_sanc_non_cont;
        vn_contrib_contribution := vn_contrib_cont + vn_contrib_non_cont + vn_new_fees + vn_pr_and_pc;
        vn_contrib_contribution := round(vn_contrib_contribution,2) * -1;
        synchronize;

        IF vn_contrib_contribution is null THEN
          Set_Application_Property(cursor_style,'Default');
          Hide_View('PLEASE_WAIT_2');
  	      alert_stop_ok('Error calculating contribution, please check costs for null values.');
          exit_form(NO_VALIDATE);
        END IF;

        :project_request_budget_mbk.budget_code_sanction_amount := vn_contrib_contribution;
        :project_budget_control_sbk.di_contribution := vn_contrib_contribution;

      ELSE --c_budget_code_details not found
        CLOSE c_budget_code_details;
        Set_Application_Property(cursor_style,'Default');
        Hide_View('PLEASE_WAIT_2');
  	    alert_stop_ok('Invalid income code combination.  Please review and amend project summary.');
        exit_form(NO_VALIDATE);
      END IF;
    ELSE 
      Set_Application_Property(cursor_style,'Default');
      Hide_View('PLEASE_WAIT_2');
  	  alert_stop_ok('No capital code found, please generate project summary to create capital code.');
      exit_form(NO_VALIDATE);
    END IF;
  END IF;  
  CLOSE cs_capital;

  Go_Block('project_request_budget_mbk');
  First_Record;
END;

--- rt_project_raise\rtpr_old_get_capital_code.pl ---
PROCEDURE get_capital_code IS

  vn_sanc_contribution    NUMBER := 0;
  vn_contrib_contribution NUMBER := 0;
  vn_sanc_cont            NUMBER := 0;
  vn_sanc_non_cont        NUMBER := 0;
  vn_contrib_cont         NUMBER := 0;
  vn_contrib_non_cont     NUMBER := 0;
  vn_fee_amount           NUMBER := 0;
  vn_recovered            NUMBER := 0;
  vn_pr_and_pc            NUMBER := 0;
  vn_new_fees							NUMBER := 0;
  vn_account_no           NUMBER;
  vn_product_code         NUMBER;
  vn_alert                NUMBER;
  v2_budget_code          VARCHAR2(2);
  vn_terms_split_id_full  NUMBER;
  vn_vat_rate_full        NUMBER;
  vn_sanc_amount          NUMBER;

  CURSOR cs_capital IS
     SELECT A.budget_code
       FROM budget_code A, budget_code_for_scheme B
      WHERE A.budget_code = B.budget_code
        AND A.date_from = B.budget_code_date_from
        AND B.scheme_id = :project_request_sbk.scheme_id
        AND B.scheme_version = :project_request_sbk.scheme_version
        AND A.type_of_expenditure_ri = 258; 

  CURSOR c1 IS
    SELECT income_product_number, income_product_code
      FROM income_for_scheme_version 
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version
       AND type_of_expenditure_ri IN (258,222)
     ORDER BY income_product_number;

  CURSOR c2 (pn_inc_num IN NUMBER, pn_inc_code IN NUMBER) IS
    SELECT icl.budget_code, lpad(icl.ecc,3,'0') ecc, icl.tax_code, bc.date_from
      FROM income_code_lookup icl, budget_code bc
     WHERE icl.account_number = pn_inc_num
       AND icl.product_code = pn_inc_code
       and icl.budget_code = bc.budget_code
       and bc.date_to is null;
       
--
-- CCN13700 start
--
	     
  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;
     
  vd_date_of_estimate DATE; 
  vn_margins_quantity NUMBER(3);
  
  CURSOR get_margins_quantity IS
    SELECT quantity
        FROM terms_general_standard
       WHERE terms_standard_ri IN (SELECT reference_item_id
                                     FROM reference_item
                                    WHERE reference_type = 'Type Of Terms Standard'
				      AND character_field1 = 'Margin(%)')
              AND vd_date_of_estimate BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate));        

  CURSOR c3 (vn_exp_type IN NUMBER)IS
    SELECT DISTINCT 1, round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*nvl(bcfss.percentage_split,0)/100 ),2) CONTESTABLE_COST,
           round(sbfm.NONcontestable_cost*nvl(bcfss.percentage_split,0)/100,2) NONCONTESTABLE_COST, 
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,NVL(NON_CONT.QUANTITY,2)+NVL(CONT.QUANTITY,2)  total_quantity,
           nvl(swe.description_for_customer,ci.description) swe_description,sbfm.description,sbfm.cost_item_id 
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           cost_item_element cie,
           cost_item_element non_cont,
           cost_item_element cont,
           work_category_for_scheme wcfs,
           standard_work_element swe,
           work_category wc,
           work_category_association wca,
           budget_code_for_scheme_split bcfss,
           budget_code bc
     WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
       AND sbfm.scheme_version = :project_request_sbk.scheme_version
       AND sbfm.userid = user_pk.get_userid
       AND (sbfm.contestable_cost > 0 
        OR sbfm.noncontestable_cost >0)
       AND ci.cost_item_id = sbfm.cost_item_id
       AND ci.cost_item_indicator != 'T'
       AND cie.cost_item_id = ci.cost_item_id
       AND cie.budget_code IS NULL
       AND swe.standard_work_element_id(+) = ci.standard_work_element_id
       AND bcfss.scheme_id = sbfm.scheme_id
       AND bcfss.scheme_version = sbfm.scheme_version
       AND bc.budget_code = bcfss.budget_code
       AND bc.date_from = bcfss.budget_code_date_from
       AND bc.type_of_expenditure_ri = vn_exp_type
       AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
       AND wc.work_category = wcfs.work_category_1
       AND wca.work_category_1(+) = wcfs.work_category_1
       AND wca.work_category_2(+) = wcfs.work_category_2
       AND non_cont.cost_item_id(+) = sbfm.cost_item_id
       AND non_cont.type_of_cost_ri(+) = 206
       AND cont.cost_item_id(+) = sbfm.cost_item_id
       AND cont.type_of_cost_ri(+) = 207
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
     UNION
    SELECT DISTINCT 1, round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2) CONTESTABLE_COST,
           round(sbfm.NONcontestable_cost,2) NONCONTESTABLE_COST,
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, NVL(NON_CONT.QUANTITY,2)+NVL(CONT.QUANTITY,2) total_quantity,
           nvl(swe.description_for_customer,ci.description) swe_description,sbfm.description,sbfm.cost_item_id
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           cost_item_element non_cont,
           cost_item_element cont,
           standard_work_element swe,
           work_category_association wca,
           work_category wc,
           cost_item_allocation$v cia
     WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
       AND sbfm.scheme_version = :project_request_sbk.scheme_version
       AND sbfm.userid = user_pk.get_userid
       AND (sbfm.contestable_cost > 0 
        OR sbfm.noncontestable_cost >0)
       AND ci.cost_item_id = sbfm.cost_item_id
       AND ci.cost_item_indicator != 'T'
       AND cia.cost_item_id = ci.cost_item_id
       AND cia.type_of_expenditure_ri = vn_exp_type
       AND cia.split_indicator = 0
       AND swe.standard_work_element_id(+) = ci.standard_work_element_id
       AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
       AND wc.work_category = wcfs.work_category_1
       AND wca.work_category_1(+) = wcfs.work_category_1
       AND wca.work_category_2(+) = wcfs.work_category_2
       AND non_cont.cost_item_id(+) = ci.cost_item_id
       AND non_cont.type_of_cost_ri(+) = 206
       AND cont.cost_item_id(+) = ci.cost_item_id
       AND cont.type_of_cost_ri(+) = 207
     UNION
    SELECT DISTINCT 1, round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2) CONTESTABLE_COST,
           round(sbfm.NONcontestable_cost,2) NONCONTESTABLE_COST,
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
           NVL(NON_CONT.QUANTITY,2)+NVL(CONT.QUANTITY,2) total_quantity,
           nvl(swe.description_for_customer,cip.description) swe_description,
           sbfm.description,
           sbfm.cost_item_id
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           cost_item_element non_cont,
           cost_item_element cont,
           standard_work_element swe,
           work_category_association wca,
           work_category wc,
           cost_item_allocation$v cia,
           cost_item cip
     WHERE sbfm.scheme_id = :project_request_sbk.scheme_id
       AND sbfm.scheme_version = :project_request_sbk.scheme_version
       AND sbfm.userid = user_pk.get_userid
       AND (sbfm.contestable_cost > 0 
        OR sbfm.noncontestable_cost >0)
       AND cip.cost_item_id = sbfm.cost_item_id
       AND cip.cost_item_indicator != 'T'
       AND ci.parent_cost_item_id = cip.cost_item_id
       AND cia.cost_item_id = ci.cost_item_id
       AND cia.type_of_expenditure_ri = vn_exp_type
       AND cia.split_indicator = 0
       AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
       AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
       AND wc.work_category = wcfs.work_category_1
       AND wca.work_category_1(+) = wcfs.work_category_1
       AND wca.work_category_2(+) = wcfs.work_category_2
       AND non_cont.cost_item_id(+) = sbfm.cost_item_id
       AND non_cont.type_of_cost_ri(+) = 206
       AND cont.cost_item_id(+) = sbfm.cost_item_id
       AND cont.type_of_cost_ri(+) = 207
     UNION
  select distinct 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
  (select distinct 2, round(sbfm.cont_travel_cost,2) CONTESTABLE_COST,
           round(sbfm.noncont_travel_cost,2) NONCONTESTABLE_COST,
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
           0 total_quantity,
           'Travel',
           bc.budget_code, 
           wcfs.work_cat_for_scheme_id
      from travel_cost_for_margins sbfm,
           work_category_for_scheme wcfs,
           work_category_association wca,
           BUDGET_CODE BC,
           work_category wc
     where wc.work_category(+) = wcfs.work_category_2
       and wca.work_category_1(+) = wcfs.work_category_1
       and wca.work_category_2(+) = wcfs.work_category_2
       AND (sbfm.cont_travel_cost > 0 
        OR sbfm.noncont_travel_cost >0)
       AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
       AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
       ANd bc.type_of_expenditure_ri = vn_exp_type
       and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       and sbfm.scheme_id = wcfs.scheme_id
       and sbfm.scheme_version = wcfs.scheme_version
       and sbfm.scheme_id = :project_request_sbk.scheme_id
       and sbfm.scheme_version = :project_request_sbk.scheme_version
       AND sbfm.userid = user_pk.get_userid
   UNION
    select distinct 2, round(sbfm.cont_travel_cost*vn_margins_quantity/100,2) CONTESTABLE_COST,
              0 NONCONTESTABLE_COST,
              nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
              0 total_quantity,
              'Travel',
              bc.budget_code, 
              wcfs.work_cat_for_scheme_id
         from travel_cost_for_margins sbfm,
              work_category_for_scheme wcfs,
              work_category_association wca,
              BUDGET_CODE BC,
              work_category wc,
              budget_code_margin_applicable bcma
        where wc.work_category(+) = wcfs.work_category_2
          and wca.work_category_1(+) = wcfs.work_category_1
          and wca.work_category_2(+) = wcfs.work_category_2
          AND (sbfm.cont_travel_cost > 0 
           OR sbfm.noncont_travel_cost >0)
          AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
          AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
          and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
          AND sbfm.budget_code = bcma.BUDGET_CODE
          and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
          ANd bc.type_of_expenditure_ri = vn_exp_type
          and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
          and sbfm.scheme_id = wcfs.scheme_id
          and sbfm.scheme_version = wcfs.scheme_version
          and sbfm.scheme_id = :project_request_sbk.scheme_id
          and sbfm.scheme_version = :project_request_sbk.scheme_version
          AND sbfm.userid = user_pk.get_userid)
        group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  CURSOR c4 IS
    SELECT SUM(CIE.QUANTITY) COST_OF_FEE
      FROM COST_ITEM_ELEMENT CIE,
           COST_ITEM         CI
     WHERE CI.SCHEME_ID = :project_request_sbk.scheme_id
       AND CI.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND CI.COST_ITEM_INDICATOR = 'F'
       AND CI.COST_ITEM_ID = CIE.COST_ITEM_ID;

  CURSOR c5 IS
    SELECT COMM_CREDIT_VALUE
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :project_request_sbk.scheme_id
       AND TBCFS.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND TBCFS.TERMS_BUDGET_CAT_ID = TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE = BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
       AND TBCFS.TERMS_BUDGET_CAT_ID = TS.TERMS_BUDGET_CAT_ID;

  CURSOR c6 IS
    SELECT distinct nvl(potential_refund,0)+nvl(past_codes_amount,0) pr_and_pc
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = :project_request_sbk.scheme_id
       AND TBCFS.SCHEME_VERSION = :project_request_sbk.scheme_version
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI IN (258,222)
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;

  CURSOR get_contrib_fees Is
    select SUM(FEES)
      FROM(select sum(round(sbfm.fees_cost)) FEES
             from scheme_breakdown_for_margins sbfm, 
                  cost_item ci, 
                  work_category_for_scheme wcfs,
                  work_category wc,
                  historic_swe hs
            where sbfm.cost_item_id = ci.cost_item_id
              and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND wcfs.work_category_2(+) = wc.work_category
              and sbfm.fees_cost > 0 
              and sbfm.description = 'FEES'
              and sbfm.standard_work_element_id = hs.standard_work_element_id
              and hs.date_to is null
              and sbfm.scheme_id = wcfs.scheme_id
              and sbfm.scheme_version = wcfs.scheme_version
              and sbfm.scheme_id = :project_request_sbk.scheme_id
              and sbfm.scheme_version = :project_request_sbk.scheme_version
              and sbfm.userid = user_pk.get_userid
            group by wc.work_category, wc.description_for_customer);

  CURSOR get_terms_split_id_full IS
    SELECT terms_split_id
      FROM terms_split
     WHERE scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;

--  CURSOR get_vat_rate_full IS
--    SELECT quantity
--    FROM terms_general_standard
--   WHERE terms_general_standard_id = 
-- (SELECT t.TERMS_GENERAL_STANDARD_ID 
--    FROM terms_general_standard t
--   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
-- (SELECT t.TERMS_GENERAL_STANDARD_ID
--    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
--   WHERE t.terms_area_ri = 1339
--     AND t.date_from IS NOT NULL
--     AND t.date_to IS NULL 
--     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
--     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_full
--   UNION
--  SELECT t.TERMS_GENERAL_STANDARD_ID
--    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
--   WHERE t.terms_area_ri     =1339
--     AND t.terms_standard_ri =1337
--     AND t.date_from IS NOT NULL
--     AND t.date_to IS NULL
--     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
--     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_full
--     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_full)));

  CURSOR c7 IS
    SELECT sum(cont_cost1)
      FROM selected_costs
     WHERE username = user_pk.get_userid
       AND scheme_id = :project_request_sbk.scheme_id
       AND scheme_version = :project_request_sbk.scheme_version;

BEGIN

  OPEN cs_capital;
  FETCH cs_capital INTO v2_budget_code;
  IF cs_capital%NOTFOUND THEN

    null;

  ELSE

    OPEN c1;
    FETCH c1 INTO vn_account_no, vn_product_code;
    CLOSE c1;

    IF vn_account_no IS NOT NULL AND vn_product_code IS NOT NULL THEN
  	
      Go_Block('project_request_budget_mbk');
      Last_Record;
      Next_Record;

  	  :project_request_budget_mbk.account_number := vn_account_no;
  	  :project_request_budget_mbk.product_code := vn_product_code;

      :project_request_budget_mbk.project_request_id := :project_request_sbk.project_request_id;
      :project_request_budget_mbk.managed_unit := :project_request_sbk.managed_unit;
--      :project_request_budget_mbk.budget_code_date_from := sysdate;
      :project_request_budget_mbk.capital_code_ind := 'C';
  
      OPEN c2(:project_request_budget_mbk.account_number, :project_request_budget_mbk.product_code);
      FETCH c2 INTO :project_request_budget_mbk.budget_code, :project_request_budget_mbk.engineering_classification, 
                    :project_request_budget_mbk.tax_code, :project_request_budget_mbk.budget_code_date_from;
      IF c2%FOUND THEN

        CLOSE c2;
  
        dpcr_report_pk.scheme_breakdown_margins(:project_request_sbk.scheme_id, :project_request_sbk.scheme_version, user_pk.get_userid);
 
        OPEN get_date_of_estimate;
        FETCH get_date_of_estimate
        INTO vd_date_of_estimate;
        CLOSE get_date_of_estimate;
  
        OPEN get_margins_quantity;
        FETCH get_margins_quantity
        INTO vn_margins_quantity;
        CLOSE get_margins_quantity;
 
  
        FOR c3_rec IN c3(222) LOOP
          vn_sanc_cont := vn_sanc_cont + c3_rec.CONTESTABLE_COST;
          vn_sanc_non_cont := vn_sanc_non_cont + c3_rec.NONCONTESTABLE_COST;
        END LOOP;
 
        FOR c3_rec IN c3(258) LOOP
          vn_sanc_cont := vn_sanc_cont + c3_rec.CONTESTABLE_COST;
          vn_sanc_non_cont := vn_sanc_non_cont + c3_rec.NONCONTESTABLE_COST;

          vn_contrib_cont := vn_contrib_cont + c3_rec.CONTESTABLE_COST;
          vn_contrib_non_cont := vn_contrib_non_cont + c3_rec.NONCONTESTABLE_COST;
        END LOOP;
      
        OPEN c7;
        FETCH c7 INTO vn_sanc_amount;
        CLOSE c7;

        OPEN c4;
        FETCH c4 INTO vn_fee_amount;
        CLOSE c4;
  
        OPEN c5;
        FETCH c5 INTO vn_recovered;
        CLOSE c5;
    
        OPEN c6;
        FETCH c6 INTO vn_pr_and_pc;
        CLOSE c6;

        OPEN get_contrib_fees;
        FETCH get_contrib_fees INTO vn_new_fees;
        CLOSE get_contrib_fees;
      
        if vn_new_fees is null then 
        	
          Set_Application_Property(cursor_style,'Default');
          Hide_View('PLEASE_WAIT_2');

          Set_Alert_Property('STOP_YES_NO', Alert_Message_Text, 'No FEES have been included on this scheme version.  Please confirm that you wish to continue project request.');
          vn_alert := Show_Alert('STOP_YES_NO');

          IF vn_alert = Alert_Button2 THEN

            exit_form(NO_VALIDATE);

          else

            vn_new_fees := 0;

          end if;

        end if;

        OPEN get_terms_split_id_full;
        FETCH get_terms_split_id_full INTO vn_terms_split_id_full;
        CLOSE get_terms_split_id_full;
      
--      IF vn_terms_split_id_full IS NOT NULL THEN
--      	OPEN get_vat_rate_full;
--      	FETCH get_vat_rate_full INTO vn_vat_rate_full;
--      	CLOSE get_vat_rate_full;
--      END IF;

        vn_sanc_contribution := vn_sanc_cont + vn_sanc_non_cont;

        vn_contrib_contribution := vn_contrib_cont + vn_contrib_non_cont + vn_new_fees + vn_pr_and_pc;

        vn_contrib_contribution := round(vn_contrib_contribution,2) * -1;

        synchronize;

        IF vn_contrib_contribution is null THEN
          Set_Application_Property(cursor_style,'Default');
          Hide_View('PLEASE_WAIT_2');
  	      alert_stop_ok('Error calculating contribution, please check costs for null values.');
          exit_form(NO_VALIDATE);
        END IF;

      --:project_request_budget_mbk.budget_code_sanction_amount := vn_sanc_contribution;
        :project_request_budget_mbk.budget_code_sanction_amount := vn_contrib_contribution;
        :project_budget_control_sbk.di_contribution := vn_contrib_contribution;

      else --c2 not found

        CLOSE c2;
        Set_Application_Property(cursor_style,'Default');
        Hide_View('PLEASE_WAIT_2');
  	    alert_stop_ok('Invalid income code combination.  Please review and amend project summary.');
        exit_form(NO_VALIDATE);

      end if;

    else --c1 not found
	
--  IF NOT crown_owner.project_financial_approval_pk.capital_code_found(:project_request_sbk.scheme_id,:project_request_sbk.scheme_version) THEN
      Set_Application_Property(cursor_style,'Default');
      Hide_View('PLEASE_WAIT_2');
  	  alert_stop_ok('No capital code found, please generate project summary to create capital code.');
      exit_form(NO_VALIDATE);
--  END IF;


    END IF;

  END IF;  
  CLOSE cs_capital;

  Go_Block('project_request_budget_mbk');
  First_Record;

END;

--- rt_send_quote\rt_send_quote_new_build_quote_value.pl ---
PROCEDURE build_quote_value(vn_scheme_id  IN NUMBER,
                            vn_scheme_ver IN NUMBER,
                            vn_total      OUT NUMBER) IS

  vn_new_cont                   NUMBER;
  vn_new_fees                   NUMBER;
  vn_new_non_cont               NUMBER;
  vn_total_cost                 NUMBER;
  vn_reg_payment                NUMBER;
  vn_terms_split_id_full        NUMBER;
  vn_vat_rate                   NUMBER;
  v2_budget_cat_ind		          terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  vn_exp_type_ri_1							NUMBER;
  vn_exp_type_ri_2							NUMBER;
  vd_date_of_estimate           DATE;
  v2_dno                        VARCHAR2(50);

  CURSOR c_budget_category IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = vn_scheme_id
	     AND SCHEME_VERSION = vn_scheme_ver;

  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = vn_scheme_id
       AND scheme_version = vn_scheme_ver;

  CURSOR new_costs IS
    SELECT DISTINCT
            1,
            NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
            NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST,
            NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
            NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
            NVL(swe.description_for_customer,ci.description) swe_description,
            sbfm.description,
            sbfm.cost_item_id
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
		       cost_item_element cie,
		       cost_item_element	non_cont,
		       cost_item_element	cont,
		       work_category_for_scheme wcfs,
			     standard_work_element swe,
			     work_category wc,
			     work_category_association wca,
			     budget_code_for_scheme_split bcfss,
			     budget_code bc,
			    (SELECT rsi1.contingency_ind "CONTINGENCY_IND", rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version
			       FROM terms_split ts1, recharge_statement_info rsi1
			      WHERE ts1.terms_split_id = rsi1.terms_split_id
			        AND rsi1.contingency_ind = 'Y') ts
		 WHERE sbfm.scheme_id = vn_scheme_id
			 AND sbfm.scheme_version = vn_scheme_ver
			 AND sbfm.userid = user_pk.get_userid
			 AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
			 and ts.scheme_id(+) = sbfm.scheme_id
			 and ts.scheme_version(+) = sbfm.SCHEME_VERSION
		   AND ci.cost_item_id = sbfm.cost_item_id
		   AND ci.cost_item_indicator != 'T'
		   AND cie.cost_item_id = ci.cost_item_id
		   AND cie.budget_code IS NULL
		   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
		   AND bcfss.scheme_id = sbfm.scheme_id
		   AND bcfss.scheme_version = sbfm.scheme_version
		   AND bc.budget_code = bcfss.budget_code
		   AND bc.date_from = bcfss.budget_code_date_from
		   AND bc.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
		   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
		   AND wc.work_category = wcfs.work_category_1
		   AND wca.work_category_1(+) = wcfs.work_category_1
		   AND wca.work_category_2(+) = wcfs.work_category_2
		   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
		   AND non_cont.type_of_cost_ri(+) = 206
		   AND cont.cost_item_id(+) = sbfm.cost_item_id
		   AND cont.type_of_cost_ri(+) = 207
		   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
     UNION
    SELECT DISTINCT
            1,
					  NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
					  NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
					  NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
					  NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
					  NVL(swe.description_for_customer,ci.description) swe_description,
					  sbfm.description,
					  sbfm.cost_item_id
		 	FROM scheme_breakdown_for_margins sbfm,
			     cost_item ci,
				   work_category_for_scheme wcfs,
				   cost_item_element non_cont,
				   cost_item_element cont,
				   standard_work_element swe,
				   work_category_association wca,
				   work_category wc,
				   cost_item_allocation$v cia,
			    (SELECT rsi1.contingency_ind "CONTINGENCY_IND", rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version
			       FROM terms_split ts1, recharge_statement_info rsi1
			      WHERE ts1.terms_split_id = rsi1.terms_split_id
			        AND rsi1.contingency_ind = 'Y') ts
  	 WHERE sbfm.scheme_id = vn_scheme_id
		   AND sbfm.scheme_version = vn_scheme_ver
			 AND sbfm.userid = user_pk.get_userid
			 AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
			 and ts.scheme_id(+) = sbfm.scheme_id
			 and ts.scheme_version(+) = sbfm.SCHEME_VERSION
			 AND ci.cost_item_id = sbfm.cost_item_id
			 AND ci.cost_item_indicator != 'T'
			 AND cia.cost_item_id = ci.cost_item_id
			 AND cia.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
			 AND cia.split_indicator = 0
			 AND swe.standard_work_element_id(+) = ci.standard_work_element_id
			 AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
			 AND wc.work_category = wcfs.work_category_1
		   AND wca.work_category_1(+) = wcfs.work_category_1
			 AND wca.work_category_2(+) = wcfs.work_category_2
			 AND non_cont.cost_item_id(+) = ci.cost_item_id
			 AND non_cont.type_of_cost_ri(+) = 206
			 AND cont.cost_item_id(+) = ci.cost_item_id
			 AND cont.type_of_cost_ri(+) = 207
     UNION
    SELECT DISTINCT
            1,
            NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
					  NVL(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.NONcontestable_cost,2),ROUND(sbfm.NONcontestable_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
					  NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
					  NVL(NON_CONT.QUANTITY,0) + NVL(CONT.QUANTITY,0) total_quantity,
					  NVL(swe.description_for_customer, cip.description) swe_description,
					  sbfm.description,
					  sbfm.cost_item_id
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           cost_item_element non_cont,
           cost_item_element cont,
           standard_work_element swe,
           work_category_association wca,
           work_category wc,
           cost_item_allocation$v cia,
           cost_item cip,
			    (SELECT rsi1.contingency_ind "CONTINGENCY_IND", rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version
			       FROM terms_split ts1, recharge_statement_info rsi1
			      WHERE ts1.terms_split_id = rsi1.terms_split_id
			        AND rsi1.contingency_ind = 'Y') ts
     WHERE sbfm.scheme_id = vn_scheme_id
       AND sbfm.scheme_version = vn_scheme_ver
       AND sbfm.userid = user_pk.get_userid
       AND (sbfm.contestable_cost > 0 OR sbfm.noncontestable_cost > 0)
       and ts.scheme_id(+) = sbfm.scheme_id
       and ts.scheme_version(+) = sbfm.SCHEME_VERSION
       AND cip.cost_item_id = sbfm.cost_item_id
       AND cip.cost_item_indicator != 'T'
       AND ci.parent_cost_item_id = cip.cost_item_id
       AND cia.cost_item_id = ci.cost_item_id
       AND cia.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
       AND cia.split_indicator = 0
       AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
       AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
       AND wc.work_category = wcfs.work_category_1
       AND wca.work_category_1(+) = wcfs.work_category_1
       AND wca.work_category_2(+) = wcfs.work_category_2
       AND non_cont.cost_item_id(+) = sbfm.cost_item_id
       AND non_cont.type_of_cost_ri(+) = 206
       AND cont.cost_item_id(+) = sbfm.cost_item_id
       AND cont.type_of_cost_ri(+) = 207
     UNION
    select 2,
           sum(CONTESTABLE_COST),
           sum(NONCONTESTABLE_COST),
           work_cat_desc,
           total_quantity,
           'Travel',
           budget_code,
           work_cat_for_scheme_id
     FROM (SELECT DISTINCT
                    2,
                    DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
                    DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.noncont_travel_cost,2),ROUND(sbfm.noncont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
                    NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                    0 total_quantity,
                    'Travel',
                    bc.budget_code,
                    wcfs.work_cat_for_scheme_id
             FROM travel_cost_for_margins sbfm,
                  work_category_for_scheme wcfs,
                  work_category_association wca,
                  budget_code bc,
                  work_category wc,
                  cost_item ci,
                 (SELECT rsi1.contingency_ind "CONTINGENCY_IND", rsi1.contingency_amount "CONTINGENCY_AMOUNT", ts1.scheme_id, ts1.scheme_version
                    FROM terms_split ts1, recharge_statement_info rsi1
                   WHERE ts1.terms_split_id = rsi1.terms_split_id
                     AND rsi1.contingency_ind = 'Y') ts
            WHERE wc.work_category(+) = wcfs.work_category_2
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost >0)
              AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
              AND ci.scheme_id = sbfm.scheme_id
              AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
              AND ci.COST_ITEM_INDICATOR = 'T'
              AND ts.scheme_id(+) = sbfm.scheme_id
              AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
              AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
              AND bc.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
              AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND sbfm.scheme_id = wcfs.scheme_id
              AND sbfm.scheme_version = wcfs.scheme_version
              AND sbfm.scheme_id = vn_scheme_id
              AND sbfm.scheme_version = vn_scheme_ver
              AND sbfm.userid = user_pk.get_userid
            UNION
           SELECT DISTINCT
                    2,
                    ROUND(DECODE(NVL(ts.CONTINGENCY_IND,'N'),'N',ROUND(sbfm.cont_travel_cost,2),ROUND(sbfm.cont_travel_cost,2)*NVL(ts.CONTINGENCY_AMOUNT,0)/100+ROUND(sbfm.cont_travel_cost,2))*bcma.margin/100,2) CONTESTABLE_COST,
                    0 NONCONTESTABLE_COST,
                    NVL(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
                    0 total_quantity,
                    'Travel',
                    bc.budget_code,
                    wcfs.work_cat_for_scheme_id
             FROM travel_cost_for_margins sbfm,
                  work_category_for_scheme wcfs,
                  work_category_association wca,
                  budget_code bc,
                  work_category wc,
                  cost_item ci,
                  scheme_version sv,
                  budget_code_margin_applicable bcma,
                 (SELECT rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version
                    FROM terms_split ts1, RECHARGE_STATEMENT_INFO rsi1
                   WHERE ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
                     AND rsi1.CONTINGENCY_IND = 'Y') ts
            WHERE wc.work_category(+) = wcfs.work_category_2
              AND wca.work_category_1(+) = wcfs.work_category_1
              AND wca.work_category_2(+) = wcfs.work_category_2
              AND (sbfm.cont_travel_cost > 0 OR sbfm.noncont_travel_cost > 0)
              AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
              AND ci.scheme_id = sbfm.scheme_id
              AND ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
              AND ci.COST_ITEM_INDICATOR = 'T'
              AND ts.scheme_id(+) = sbfm.scheme_id
              AND ts.scheme_version(+) = sbfm.SCHEME_VERSION
              AND sbfm.budget_code = bcma.budget_code
              AND sbfm.engineering_classification = bcma.engineering_classification
              AND bcma.dno = v2_dno
              AND sbfm.budget_code_date_from = bc.date_from
              AND sbfm.budget_code_date_from = bcma.budget_code_date_from
              AND vd_date_of_estimate BETWEEN bcma.date_from AND bcma.date_to
              AND sv.scheme_id = sbfm.scheme_id
              AND sv.scheme_version = sbfm.scheme_version
              AND bc.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
              AND sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
              AND sbfm.scheme_id = wcfs.scheme_id
              AND sbfm.scheme_version = wcfs.scheme_version
              AND sbfm.scheme_id = vn_scheme_id
              AND sbfm.scheme_version = vn_scheme_ver
              AND sbfm.userid = user_pk.get_userid)
            GROUP BY work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;

  CURSOR get_fees Is
    SELECT sum(ROUND(sbfm.fees_cost)) FEES
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           work_category wc,
           historic_swe hs
     WHERE sbfm.cost_item_id = ci.cost_item_id
       AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       AND wcfs.work_category_2(+) = wc.work_category
       AND sbfm.fees_cost > 0
       AND sbfm.description = 'FEES'
       AND sbfm.standard_work_element_id = hs.standard_work_element_id
       AND hs.date_to is null
       AND sbfm.scheme_id = wcfs.scheme_id
       AND sbfm.scheme_version = wcfs.scheme_version
       AND sbfm.scheme_id = vn_scheme_id
       AND sbfm.scheme_version = vn_scheme_ver
       AND sbfm.userid = user_pk.get_userid
     GROUP BY wc.work_category, wc.description_for_customer;

  CURSOR terms_recovered_asset IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM terms_split ts,
           budget_code bc,
           terms_budget_code_for_cat tbcfc,
           terms_budget_cat_for_scheme tbcfs
     WHERE tbcfs.scheme_id = vn_scheme_id
       AND tbcfs.scheme_version = vn_scheme_ver
       AND tbcfs.terms_budget_cat_id=tbcfc.terms_budget_cat_id
       AND tbcfc.budget_code=bc.budget_code
       AND tbcfc.budget_code_date_from=bc.date_from
       AND bc.type_of_expenditure_ri IN (vn_exp_type_ri_1, vn_exp_type_ri_2)
       AND tbcfs.terms_budget_cat_id=ts.terms_budget_cat_id;

  CURSOR get_terms_split_id_full IS
    SELECT terms_split_id
      FROM terms_split
     WHERE scheme_id = vn_scheme_id
       AND scheme_version = vn_scheme_ver;

  CURSOR get_vat_rate_full IS
    SELECT quantity
      FROM terms_general_standard
     WHERE terms_general_standard_id = (SELECT t.TERMS_GENERAL_STANDARD_ID
                                          FROM terms_general_standard t
                                         WHERE t.TERMS_GENERAL_STANDARD_ID IN (SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                 FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                WHERE t.terms_area_ri = 1339
                                                                                  AND t.date_from IS NOT NULL
                                                                                  AND t.date_to IS NULL
                                                                                  AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
                                                                                  AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_full
                                                                                UNION
                                                                               SELECT t.TERMS_GENERAL_STANDARD_ID
                                                                                 FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
                                                                                WHERE t.terms_area_ri     =1339
                                                                                  AND t.terms_standard_ri =1337
                                                                                  AND t.date_from IS NOT NULL
                                                                                  AND t.date_to IS NULL
                                                                                  AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
                                                                                  AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_full
                                                                                  AND NOT EXISTS (SELECT 1
                                                                                                    FROM USER_APPL_TERMS_GEN_STAN
                                                                                                   WHERE TERMS_SPLIT_ID = vn_terms_split_id_full)));

BEGIN

  v2_dno := crown_owner.util_scheme_procs.get_dno_for_scheme(vn_scheme_id, vn_scheme_ver);

  OPEN c_budget_category;
	FETCH c_budget_category
	INTO v2_budget_cat_ind;
	CLOSE c_budget_category;

  IF v2_budget_cat_ind IN ('E','N')  THEN
    vn_exp_type_ri_1 := '226';
    vn_exp_type_ri_2 := '227';
 	  dpcr_report_pk.scheme_breakdown_margins(vn_scheme_id,vn_scheme_ver,user_pk.get_userid,vn_exp_type_ri_1);
  ELSE
    vn_exp_type_ri_1 := '258';
 	  dpcr_report_pk.scheme_breakdown_margins(vn_scheme_id,vn_scheme_ver,user_pk.get_userid);
  END IF;

  vn_new_cont     := 0;
  vn_new_fees     := 0;
  vn_new_non_cont := 0;
  vn_total_cost   := 0;
  vn_reg_payment  := 0;

  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;

  OPEN terms_recovered_asset;
  FETCH terms_recovered_asset
  INTO vn_reg_payment;
  CLOSE terms_recovered_asset;

  FOR get_rec IN new_costs LOOP
    vn_new_cont := vn_new_cont+get_rec.CONTESTABLE_COST;
    vn_new_non_cont := vn_new_non_cont+get_rec.NONCONTESTABLE_COST;
  END LOOP;

  FOR get_rec IN get_fees LOOP
    vn_new_fees := vn_new_fees+get_rec.fees;
  END LOOP;

  vn_total := NVL(vn_new_cont,0)+NVL(vn_new_non_cont,0)+NVL(vn_new_fees,0)+NVL(vn_reg_payment,0);

  OPEN get_terms_split_id_full;
  FETCH get_terms_split_id_full
  INTO vn_terms_split_id_full;
  CLOSE get_terms_split_id_full;

  IF vn_terms_split_id_full IS NOT NULL THEN
  	OPEN get_vat_rate_full;
  	FETCH get_vat_rate_full
    INTO vn_vat_rate;
    CLOSE get_vat_rate_full;
  END IF;

  vn_total := ROUND(vn_total + vn_vat_rate * vn_total/100, 2);

END;

--- rt_send_quote\rt_send_quote_old_build_quote_value.pl ---
PROCEDURE build_quote_value(vn_scheme_id  IN NUMBER,
                            vn_scheme_ver IN NUMBER,
                            vn_total      OUT NUMBER) IS

  vn_new_cont                   NUMBER;
  vn_new_fees                   NUMBER;
  vn_new_non_cont               NUMBER;
  vn_total_cost                 NUMBER;
  vn_reg_payment                NUMBER;
  vn_terms_split_id_full        NUMBER;
  vn_vat_rate                   NUMBER;
  v2_budget_cat_ind		terms_budget_cat_for_scheme.budget_category_type_ind%TYPE;
  vn_exp_type_ri_1							NUMBER;
  vn_exp_type_ri_2							NUMBER;  
  
  	CURSOR budget_category IS
	  SELECT BUDGET_CATEGORY_TYPE_IND
	    FROM terms_budget_cat_for_scheme
	   WHERE SCHEME_ID = vn_scheme_id
	     AND SCHEME_VERSION = vn_scheme_ver;  
	     
--
-- CCN13700 start
--
	     
  CURSOR get_date_of_estimate IS
    SELECT distinct date_of_estimate
      FROM scheme_version
     WHERE scheme_id = vn_scheme_id
       AND scheme_version = vn_scheme_ver;
     
  vd_date_of_estimate DATE; 
  vn_margins_quantity NUMBER(3);
  
  CURSOR get_margins_quantity IS
    SELECT quantity
      FROM terms_general_standard
     WHERE terms_standard_ri IN (SELECT reference_item_id
                                   FROM reference_item
                                  WHERE reference_type = 'Type Of Terms Standard'
		                                AND character_field1 = 'Margin(%)')
       AND trunc(vd_date_of_estimate) BETWEEN trunc(date_from) AND nvl(trunc(date_to),trunc(sysdate)); 

--
-- start change CCN79668
--  
       
  v2_check_ssq VARCHAR2(1);     
       
  CURSOR check_ssq IS
  SELECT 'X'
    FROM scheme_for_sub_enquiry
   WHERE scheme_id  = vn_scheme_id
     AND scheme_version = vn_scheme_ver
     AND ENQUIRY_CATEGORY_ID IN (409,410,402,403,415,73,76,496,399,497,405,666);  

--
-- end change CCN79668
--  	     
	     

  CURSOR new_costs IS
    SELECT DISTINCT 1, 
           nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost*bcfss.percentage_split/100 ),2)),0) CONTESTABLE_COST,
           nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2),round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost*bcfss.percentage_split/100,2)),0) NONCONTESTABLE_COST, 
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc,
           NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0)  total_quantity,
           nvl(swe.description_for_customer,ci.description) swe_description,
           sbfm.description,
           sbfm.cost_item_id 
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
		       cost_item_element cie,
		       cost_item_element	non_cont,
		       cost_item_element	cont,
		       work_category_for_scheme wcfs,
			     standard_work_element swe,
			     work_category wc,
			     work_category_association wca,
			     budget_code_for_scheme_split bcfss,
			     budget_code bc,
			     (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
			        from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
			       where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
			         and rsi1.CONTINGENCY_IND = 'Y') ts
		 WHERE sbfm.scheme_id = vn_scheme_id
			 AND sbfm.scheme_version = vn_scheme_ver
			 AND sbfm.userid = user_pk.get_userid
			 AND (sbfm.contestable_cost > 0 
			  OR sbfm.noncontestable_cost >0)
			 and ts.scheme_id(+) = sbfm.scheme_id
			 and ts.scheme_version(+) = sbfm.SCHEME_VERSION
		   AND ci.cost_item_id = sbfm.cost_item_id
		   AND ci.cost_item_indicator != 'T'
		   AND cie.cost_item_id = ci.cost_item_id
		   AND cie.budget_code IS NULL
		   AND swe.standard_work_element_id(+) = ci.standard_work_element_id
		   AND bcfss.scheme_id = sbfm.scheme_id
		   AND bcfss.scheme_version = sbfm.scheme_version
		   AND bc.budget_code = bcfss.budget_code
		   AND bc.date_from = bcfss.budget_code_date_from
		   AND bc.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
		   AND wcfs.work_cat_for_scheme_id = bcfss.work_cat_for_scheme_id
		   AND wc.work_category = wcfs.work_category_1
		   AND wca.work_category_1(+) = wcfs.work_category_1
		   AND wca.work_category_2(+) = wcfs.work_category_2
		   AND non_cont.cost_item_id(+) = sbfm.cost_item_id
		   AND non_cont.type_of_cost_ri(+) = 206
		   AND cont.cost_item_id(+) = sbfm.cost_item_id
		   AND cont.type_of_cost_ri(+) = 207
		   AND ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id   
     UNION
    SELECT DISTINCT 1, 
					 nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(ci.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
					 nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
					 nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
					 NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
					 nvl(swe.description_for_customer,ci.description) swe_description,
					 sbfm.description,
					 sbfm.cost_item_id
		 	FROM scheme_breakdown_for_margins sbfm,
			    	cost_item ci,
				    work_category_for_scheme wcfs,
				    cost_item_element non_cont,
				    cost_item_element cont,
				    standard_work_element swe,
				    work_category_association wca,
				    work_category wc,
				    cost_item_allocation$v cia,
				   (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
				      from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
				     where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
				       and rsi1.CONTINGENCY_IND = 'Y') ts
		 WHERE sbfm.scheme_id = vn_scheme_id
		   AND sbfm.scheme_version = vn_scheme_ver
			 AND sbfm.userid = user_pk.get_userid
			 AND (sbfm.contestable_cost > 0 
			  OR sbfm.noncontestable_cost >0)
			 and ts.scheme_id(+) = sbfm.scheme_id
			 and ts.scheme_version(+) = sbfm.SCHEME_VERSION
			 AND ci.cost_item_id = sbfm.cost_item_id
			 AND ci.cost_item_indicator != 'T'
			 AND cia.cost_item_id = ci.cost_item_id
			 AND cia.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
			 AND cia.split_indicator = 0
			 AND swe.standard_work_element_id(+) = ci.standard_work_element_id
			 AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
			 AND wc.work_category = wcfs.work_category_1
		   AND wca.work_category_1(+) = wcfs.work_category_1
			 AND wca.work_category_2(+) = wcfs.work_category_2
			 AND non_cont.cost_item_id(+) = ci.cost_item_id
			 AND non_cont.type_of_cost_ri(+) = 206
			 AND cont.cost_item_id(+) = ci.cost_item_id
			 AND cont.type_of_cost_ri(+) = 207
     UNION
    SELECT DISTINCT 1, 
           nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2),round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(terms_margin_pk.margin_cost(cip.cost_item_id,sbfm.contestable_cost),2)),0) CONTESTABLE_COST,
					 nvl(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.NONcontestable_cost,2),round(sbfm.NONcontestable_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.NONcontestable_cost,2)),0) NONCONTESTABLE_COST,
					 nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2) work_cat_desc, 
					 NVL(NON_CONT.QUANTITY,0)+NVL(CONT.QUANTITY,0) total_quantity,
					 nvl(swe.description_for_customer,cip.description) swe_description,
					 sbfm.description,
					 sbfm.cost_item_id
      FROM scheme_breakdown_for_margins sbfm,
           cost_item ci,
           work_category_for_scheme wcfs,
           cost_item_element non_cont,
           cost_item_element cont,
           standard_work_element swe,
           work_category_association wca,
           work_category wc,
           cost_item_allocation$v cia,
           cost_item cip,
           (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
              from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
             where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
               and rsi1.CONTINGENCY_IND = 'Y') ts
     WHERE sbfm.scheme_id = vn_scheme_id
       AND sbfm.scheme_version = vn_scheme_ver
       AND sbfm.userid = user_pk.get_userid
       AND (sbfm.contestable_cost > 0 
        OR sbfm.noncontestable_cost >0)
       and ts.scheme_id(+) = sbfm.scheme_id
       and ts.scheme_version(+) = sbfm.SCHEME_VERSION
       AND cip.cost_item_id = sbfm.cost_item_id
       AND cip.cost_item_indicator != 'T'
       AND ci.parent_cost_item_id = cip.cost_item_id
       AND cia.cost_item_id = ci.cost_item_id
       AND cia.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
       AND cia.split_indicator = 0
       AND swe.standard_work_element_id(+) = sbfm.standard_work_element_id
       AND wcfs.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
       AND wc.work_category = wcfs.work_category_1
       AND wca.work_category_1(+) = wcfs.work_category_1
       AND wca.work_category_2(+) = wcfs.work_category_2
       AND non_cont.cost_item_id(+) = sbfm.cost_item_id
       AND non_cont.type_of_cost_ri(+) = 206
       AND cont.cost_item_id(+) = sbfm.cost_item_id
       AND cont.type_of_cost_ri(+) = 207
     UNION
    select 2,sum(CONTESTABLE_COST), sum(NONCONTESTABLE_COST),work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id FROM
   (select distinct 2, 
           decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2)) CONTESTABLE_COST,
           decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.noncont_travel_cost,2),round(sbfm.noncont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.noncont_travel_cost,2)) NONCONTESTABLE_COST,
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
           0 total_quantity,
           'Travel',
           bc.budget_code, 
           wcfs.work_cat_for_scheme_id
      from travel_cost_for_margins sbfm,
           work_category_for_scheme wcfs,
           work_category_association wca,
           BUDGET_CODE BC,
           work_category wc,
           cost_item ci,
           (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
              from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
             where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
               and rsi1.CONTINGENCY_IND = 'Y') ts			      
     where wc.work_category(+) = wcfs.work_category_2
       and wca.work_category_1(+) = wcfs.work_category_1
       and wca.work_category_2(+) = wcfs.work_category_2
       AND (sbfm.cont_travel_cost > 0 
        OR sbfm.noncont_travel_cost >0)
       AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
       and ci.scheme_id = sbfm.scheme_id
       and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
       and ci.COST_ITEM_INDICATOR = 'T'
       and ts.scheme_id(+) = sbfm.scheme_id
       and ts.scheme_version(+) = sbfm.SCHEME_VERSION
       AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
       ANd bc.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
       and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       and sbfm.scheme_id = wcfs.scheme_id
       and sbfm.scheme_version = wcfs.scheme_version
       and sbfm.scheme_id = vn_scheme_id
       and sbfm.scheme_version = vn_scheme_ver
       and sbfm.userid = user_pk.get_userid   
     UNION
    select distinct 2, 
           round(decode(nvl(ts.CONTINGENCY_IND,'N'),'N',round(sbfm.cont_travel_cost,2),round(sbfm.cont_travel_cost,2)*nvl(ts.CONTINGENCY_AMOUNT,0)/100+round(sbfm.cont_travel_cost,2))*vn_margins_quantity/100,2) CONTESTABLE_COST,
           0 NONCONTESTABLE_COST,
           nvl(wca.description_for_customer,wcfs.work_category_1||' '||wcfs.work_category_2)  work_cat_desc,
           0 total_quantity,
           'Travel',
           bc.budget_code, 
           wcfs.work_cat_for_scheme_id
      from travel_cost_for_margins sbfm,
           work_category_for_scheme wcfs,
           work_category_association wca,
           BUDGET_CODE BC,
           work_category wc,
           cost_item ci,
           scheme_version sv,
           budget_code_margin_applicable bcma,
           (select rsi1.CONTINGENCY_IND "CONTINGENCY_IND" ,rsi1.CONTINGENCY_AMOUNT "CONTINGENCY_AMOUNT",ts1.scheme_id  ,ts1.scheme_version 
              from terms_split ts1, RECHARGE_STATEMENT_INFO rsi1 
             where ts1.TERMS_SPLIT_ID = rsi1.TERMS_SPLIT_ID
               and rsi1.CONTINGENCY_IND = 'Y') ts			      
     where wc.work_category(+) = wcfs.work_category_2
       and wca.work_category_1(+) = wcfs.work_category_1
       and wca.work_category_2(+) = wcfs.work_category_2
       AND (sbfm.cont_travel_cost > 0 
        OR sbfm.noncont_travel_cost >0)
       AND sbfm.work_cat_for_scheme_id = ci.work_cat_for_scheme_id
       and ci.scheme_id = sbfm.scheme_id
       and ci.SCHEME_VERSION = sbfm.SCHEME_VERSION
       and ci.COST_ITEM_INDICATOR = 'T'
       and ts.scheme_id(+) = sbfm.scheme_id
       and ts.scheme_version(+) = sbfm.SCHEME_VERSION
       AND sbfm.BUDGET_CODE = BC.BUDGET_CODE
       and sbfm.ENGINEERING_CLASSIFICATION = bcma.ENGINEERING_CLASSIFICATION
       AND sbfm.BUDGET_CODE_DATE_FROM = BC.DATE_FROM
       AND sbfm.budget_code = bcma.BUDGET_CODE
       and sbfm.budget_code_date_from = bcma.BUDGET_CODE_DATE_FROM
       and sv.scheme_id = sbfm.scheme_id
       and sv.scheme_version = sbfm.scheme_version
       and bcma.date_to is null
       ANd bc.type_of_expenditure_ri in (vn_exp_type_ri_1,vn_exp_type_ri_2)
       and sbfm.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       and sbfm.scheme_id = wcfs.scheme_id
       and sbfm.scheme_version = wcfs.scheme_version
       and sbfm.scheme_id = vn_scheme_id
       and sbfm.scheme_version = vn_scheme_ver
       and sbfm.userid = user_pk.get_userid)
     group by work_cat_desc,total_quantity, 'Travel',budget_code,work_cat_for_scheme_id;


  CURSOR get_fees Is
    select sum(round(sbfm.fees_cost)) FEES
      from scheme_breakdown_for_margins sbfm, 
           cost_item ci, 
           work_category_for_scheme wcfs,
           work_category wc,
           historic_swe hs
     where sbfm.cost_item_id = ci.cost_item_id
       and ci.work_cat_for_scheme_id = wcfs.work_cat_for_scheme_id
       AND wcfs.work_category_2(+) = wc.work_category
       and sbfm.fees_cost > 0 
       and sbfm.description = 'FEES'
       and sbfm.standard_work_element_id = hs.standard_work_element_id
       and hs.date_to is null
       and sbfm.scheme_id = wcfs.scheme_id
       and sbfm.scheme_version = wcfs.scheme_version
       and sbfm.scheme_id = vn_scheme_id
       and sbfm.scheme_version = vn_scheme_ver
       and sbfm.userid = user_pk.get_userid
     group by wc.work_category, wc.description_for_customer;

  CURSOR terms_recovered_asset IS
    SELECT distinct (NVL(POTENTIAL_REFUND,0)+NVL(PAST_CODES_AMOUNT,0))-NVL(COMM_CREDIT_VALUE,0)
      FROM TERMS_SPLIT TS,
           BUDGET_CODE BC,
           TERMS_BUDGET_CODE_FOR_CAT TBCFC,
           TERMS_BUDGET_CAT_FOR_SCHEME TBCFS
     WHERE TBCFS.SCHEME_ID = vn_scheme_id
       AND TBCFS.SCHEME_VERSION = vn_scheme_ver
       AND TBCFS.TERMS_BUDGET_CAT_ID=TBCFC.TERMS_BUDGET_CAT_ID
       AND TBCFC.BUDGET_CODE=BC.BUDGET_CODE
       AND TBCFC.BUDGET_CODE_DATE_FROM=BC.DATE_FROM
       AND BC.TYPE_OF_EXPENDITURE_RI IN (vn_exp_type_ri_1,vn_exp_type_ri_2)
       AND TBCFS.TERMS_BUDGET_CAT_ID=TS.TERMS_BUDGET_CAT_ID;


  CURSOR get_terms_split_id_full IS
    SELECT terms_split_id
      FROM terms_split
     WHERE scheme_id = vn_scheme_id
       AND scheme_version = vn_scheme_ver;

  CURSOR get_vat_rate_full IS
    SELECT quantity
    FROM terms_general_standard
   WHERE terms_general_standard_id = 
 (SELECT t.TERMS_GENERAL_STANDARD_ID 
    FROM terms_general_standard t
   WHERE t.TERMS_GENERAL_STANDARD_ID IN 
 (SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri = 1339
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL 
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID
     AND u.TERMS_SPLIT_ID(+) = vn_terms_split_id_full
   UNION
  SELECT t.TERMS_GENERAL_STANDARD_ID
    FROM USER_APPL_TERMS_GEN_STAN u,terms_general_standard t
   WHERE t.terms_area_ri     =1339
     AND t.terms_standard_ri =1337
     AND t.date_from IS NOT NULL
     AND t.date_to IS NULL
     AND t.TERMS_GENERAL_STANDARD_ID = u.TERMS_GENERAL_STANDARD_ID(+)
     AND u.TERMS_SPLIT_ID(+)= vn_terms_split_id_full
     AND NOT EXISTS (SELECT 1 FROM USER_APPL_TERMS_GEN_STAN WHERE TERMS_SPLIT_ID = vn_terms_split_id_full)));

Begin
	
  OPEN budget_category;
	FETCH budget_category
	INTO v2_budget_cat_ind;
	CLOSE budget_category;

  IF v2_budget_cat_ind IN ('E','N')  THEN
    vn_exp_type_ri_1 := '226';
    vn_exp_type_ri_2 := '227';
 	  dpcr_report_pk.scheme_breakdown_margins(vn_scheme_id,vn_scheme_ver,user_pk.get_userid,vn_exp_type_ri_1);
  ELSE
    vn_exp_type_ri_1 := '258';
 	  dpcr_report_pk.scheme_breakdown_margins(vn_scheme_id,vn_scheme_ver,user_pk.get_userid);    
  END IF;

  --commit;

  vn_new_cont :=0;
  vn_new_fees :=0;
  vn_new_non_cont :=0;
  vn_total_cost :=0;
  vn_reg_payment := 0;
  
  OPEN get_date_of_estimate;
  FETCH get_date_of_estimate
  INTO vd_date_of_estimate;
  CLOSE get_date_of_estimate;
  
--
-- start change CCN79668
--  
  
  OPEN check_ssq;
  FETCH check_ssq
  INTO v2_check_ssq;
  CLOSE check_ssq;
  
  IF v2_check_ssq = 'X' THEN
  	
  	vn_margins_quantity := 0;
  	
  ELSE	
  
    OPEN get_margins_quantity;
    FETCH get_margins_quantity
    INTO vn_margins_quantity;
    CLOSE get_margins_quantity;
    
  END IF;
  
--
-- end change CCN79668
--    


  OPEN terms_recovered_asset;
  FETCH terms_recovered_asset
    INTO vn_reg_payment;
  CLOSE terms_recovered_asset;

  for get_rec IN new_costs LOOP
    vn_new_cont := vn_new_cont+get_rec.CONTESTABLE_COST;
    vn_new_non_cont := vn_new_non_cont+get_rec.NONCONTESTABLE_COST;
  end LOOP;
  
  for get_rec IN get_fees LOOP
    vn_new_fees := vn_new_fees+get_rec.fees;
  end LOOP;

  vn_total := nvl(vn_new_cont,0)+nvl(vn_new_non_cont,0)+nvl(vn_new_fees,0)+NVL(vn_reg_payment,0);
  
  OPEN get_terms_split_id_full;
  FETCH get_terms_split_id_full
    INTO vn_terms_split_id_full;
  CLOSE get_terms_split_id_full;
  
  IF vn_terms_split_id_full IS NOT NULL THEN
  	OPEN get_vat_rate_full;
  	FETCH get_vat_rate_full
      INTO vn_vat_rate;
    CLOSE get_vat_rate_full;
  END IF;     
  
  vn_total := round(vn_total+vn_vat_rate*vn_total/100,2);

end;


