<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../config/db.php';
function reply($d,$s=200){http_response_code($s);echo json_encode($d);exit;}
try{
 $id=(int)($_POST['id']??0); if(!$id) { $b=json_decode(file_get_contents('php://input'),true)??[]; $id=(int)($b['id']??0); }
 $pdo->beginTransaction();
 $q=$pdo->prepare("SELECT * FROM change_requests WHERE id=? FOR UPDATE");$q->execute([$id]);$c=$q->fetch();
 if(!$c) throw new RuntimeException('Change request not found.');
 if($c['status']!=='Approved') throw new RuntimeException('Only approved change requests can be applied.');
 if((int)$c['applied']===1) throw new RuntimeException('This approved change has already been applied.');
 $p=$pdo->query("SELECT * FROM projects ORDER BY id DESC LIMIT 1 FOR UPDATE")->fetch();
 if(!$p) throw new RuntimeException('Create a project charter first.');
 $u=$pdo->prepare("UPDATE projects SET approved_budget=approved_budget+?, baseline_weeks=baseline_weeks+? WHERE id=?");
 $u->execute([$c['cost_impact'],$c['weeks_impact'],$p['id']]);
 $r=$pdo->prepare("INSERT INTO requirements(title,description,priority,status,category) VALUES(?,?, 'High','Approved','Approved change')");
 $r->execute([$c['title'],'Added through approved change request: '.$c['justification']]);
 $pdo->prepare("UPDATE change_requests SET applied=1 WHERE id=?")->execute([$id]);
 $pdo->commit();
 reply(['success'=>true,'message'=>'Approved change applied. Budget increased by PKR '.number_format((float)$c['cost_impact']).' and duration by '.$c['weeks_impact'].' weeks.']);
}catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();reply(['success'=>false,'message'=>$e->getMessage()],400);}
