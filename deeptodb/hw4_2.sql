CREATE OR REPLACE FUNCTION SubmitReview(_paper_id INT, _reviewer_id INT, _score INT)                                                                
RETURNS VOID AS $$                                                                                                                                  
DECLARE                                                                                                                                             
        n_paper_id integer;                                                                                                                        
        n_reviewer_id integer;                                                                                                                  
        n_score_records integer;                                                                                                                    
        t_paper_scores integer;                                                                                                        
        factor integer := 0;                                                                                                                        
        score integer := 0;                                                                                                                         
        cnt integer := 0;                                                                                                                           
BEGIN                                                                                                                                               
        SELECT P.id INTO n_paper_id FROM Paper P WHERE P.id = _paper_id;                                                                            
        SELECT R.id INTO n_reviewer_id FROM Reviewer R WHERE R.id = _reviewer_id;                                                                   
                                                                                                                                                    
        IF (n_paper_id IS NULL) OR (n_reviewer_id IS NULL) OR (_score < 1) OR (_score > 7)  THEN                                                    
                RAISE EXCEPTION 'INPUT_DATA_NOT_VALID';                                                                                             
        END IF;                                                                                                                                     
                                                                                                                                                    
        SELECT COUNT(*) INTO n_score_records FROM PaperReviewing PR WHERE PR.paper_id = n_paper_id AND PR.reviewer_id = n_rewiever_id;              
                                                                                                                                                    
        IF n_score_records > 0 THEN                                                                                                                 
                UPDATE PaperReviewing SET paper_id=n_paper_id, reviewer_id=n_reviewer_id, score=_score WHERE paper_id = n_paper_id AND reviewer_id = n_rewiever_id;                                    
        ELSE                                                                                                                                        
                INSERT INTO PaperReviewing(paper_id, reviewer_id, score) VALUES (n_paper_id,n_reviewer_id,_score);                                  
        END IF;                                                                                                                                     
                                                                                                                                                    
        SELECT score INTO t_paper_scores FROM PaperReviewing WHERE paper_id = n_paper_id AND reviewer_id = n_reviewer_id;                           
                                                                                                                                                    
        FOREACH score IN t_paper_scores LOOP                                                                                                        
                factor := factor + score;                                                                                                           
                cnt := cnt + 1;                                                                                                                     
        END LOOP;                                                                                                                                   
                                                                                                                                                    
        IF cnt > 0 THEN                                                                                                                             
                factor := factor/cnt;                                                                                                               
        END IF;                                                                                                                                     
                                                                                                                                                    
        IF factor > 4 THEN                                                                                                                          
                UPDATE Paper SET accepted VALUES (1) WHERE id = n_paper_id;                                                                         
        ELSE                                                                                                                                        
                UPDATE Paper SET accepted VALUES (0) WHERE id = n_paper_id;                                                                         
        END IF;                                                                                                                                     

EXCEPTION
	WHEN 'INPUT_DATA_NOT_VALID' THEN
        	RETURN 1                                                                                                                                            
	
END;                                                                                                                                                
$$ LANGUAGE plpgsql;
