DROP TABLE IF EXISTS PaperReviewing;
DROP TABLE IF EXISTS Reviewer;
DROP TABLE IF EXISTS Paper;
DROP TABLE IF EXISTS ConferenceEvent;
DROP TABLE IF EXISTS Conference;

CREATE TABLE Conference(
  id SERIAL PRIMARY KEY, name TEXT UNIQUE);

CREATE TABLE ConferenceEvent(
  id SERIAL PRIMARY KEY,
	conference_id INT REFERENCES Conference,
	year INT,
	UNIQUE(conference_id, year));

CREATE TABLE Paper(
  id SERIAL PRIMARY KEY,
  event_id INT REFERENCES ConferenceEvent,
  title TEXT,
  accepted BOOLEAN
);

CREATE TABLE Reviewer(
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE,
  name TEXT
);

CREATE TABLE PaperReviewing(
  paper_id INT REFERENCES Paper,
  reviewer_id INT REFERENCES Reviewer,
  score INT,
  UNIQUE(paper_id, reviewer_id)
);

INSERT INTO Conference(name) VALUES ('SIGMOD'), ('VLDB');
INSERT INTO ConferenceEvent(conference_id, year) VALUES (1, 2015), (1, 2016), (2, 2016);
INSERT INTO Reviewer(email, name) VALUES
    ('jennifer@stanford.edu', 'Jennifer Widom'),
    ('donald@ethz.ch', 'Donald Kossmann'),
    ('jeffrey@stanford.edu', 'Jeffrey Ullman'),
    ('jeff@google.com', 'Jeffrey Dean'),
    ('michael@mit.edu', 'Michael Stonebraker');

INSERT INTO Paper(event_id, title) VALUES
    (1, 'Paper1'),
    (2, 'Paper2'),
    (2, 'Paper3'),
    (3, 'Paper4');

INSERT INTO PaperReviewing(paper_id, reviewer_id) VALUES
    (1, 1), (1, 4), (1, 5),
    (2, 1), (2, 2), (2, 4),
    (3, 3), (3, 4), (3, 5),
    (4, 2), (4, 3), (4, 4);

CREATE OR REPLACE FUNCTION SubmitReview(_paper_id INT, _reviewer_id INT, _score INT)                                                                
RETURNS VOID AS $$                                                                                                                                  
DECLARE                                                                                                                                             
        n_paper_id Paper.id;                                                                                                                        
        n_reviewer_id Reviewer.id;                                                                                                                  
        n_score_records integer;                                                                                                                    
        t_paper_scores PaperReviewing.score;                                                                                                        
        factor integer := 0;                                                                                                                        
        score integer := 0;                                                                                                                         
        cnt integer := 0;                                                                                                                           
BEGIN                                                                                                                                               
        SELECT P.id INTO n_paper_id FROM Paper P WHERE P.id = _paper_id;                                                                            
        SELECT R.id INTO n_reviewer_id FROM Reviewer R WHERE R.id = _reviewer_id;                                                                   
                                                                                                                                                    
        IF (n_paper_id IS NULL) OR (n_reviewer_id IS NULL) OR (_score < 1) OR (_score > 7)  THEN                                                    
                RAISE EXCEPTION "Input data not valid";                                                                                             
        END IF;                                                                                                                                     
                                                                                                                                                    
        SELECT COUNT(*) INTO n_score_records FROM PaperReviewing PR WHERE PR.paper_id = n_paper_id AND PR.reviewer_id = n_rewiever_id;              
                                                                                                                                                    
        IF n_score_records > 0 THEN                                                                                                                 
                UPDATE PaperReviewing SET paper_id, reviewer_id, score VALUES (n_paper_id,n_reviewer_id,_score);                                    
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
                                                                                                                                                    
END;                                                                                                                                                
$$ LANGUAGE plpgsql;
