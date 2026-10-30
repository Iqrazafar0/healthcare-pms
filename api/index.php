<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
require_once __DIR__ . '/../config/db.php';

function out($data, int $status=200): never { http_response_code($status); echo json_encode($data, JSON_UNESCAPED_UNICODE); exit; }
function body(): array { $v=json_decode(file_get_contents('php://input'),true); return is_array($v)?$v:$_POST; }
function clean($v, int $max=5000): string { return mb_substr(trim((string)($v ?? '')),0,$max); }
function numv($v, float $default=0): float { return is_numeric($v) ? (float)$v : $default; }
function record(PDO $pdo, string $table, array $data, array $allowed, ?int $id=null): int {
    $fields=[]; $values=[];
    foreach($allowed as $f){ if(array_key_exists($f,$data)){ $fields[]="`$f`"; $values[]=$data[$f]===''?null:$data[$f]; } }
    if(!$fields) throw new InvalidArgumentException('No valid fields supplied.');
    if($id){ $sets=array_map(fn($f)=>"`$f` = ?",array_map(fn($x)=>trim($x,'`'),$fields)); $values[]=$id; $st=$pdo->prepare("UPDATE `$table` SET ".implode(',',$sets).", updated_at=NOW() WHERE id=?"); $st->execute($values); if(!$st->rowCount() && !exists($pdo,$table,$id)) throw new RuntimeException('Record not found.'); return $id; }
    $st=$pdo->prepare("INSERT INTO `$table` (".implode(',',$fields).") VALUES (".implode(',',array_fill(0,count($fields),'?')).")"); $st->execute($values); return (int)$pdo->lastInsertId();
}
function exists(PDO $pdo,string $table,int $id): bool { $s=$pdo->prepare("SELECT id FROM `$table` WHERE id=?");$s->execute([$id]);return (bool)$s->fetchColumn(); }
$resource = clean($_GET['resource'] ?? '',40);
$method = $_SERVER['REQUEST_METHOD'];
try {
 if($resource==='dashboard' && $method==='GET'){
   $p=$pdo->query("SELECT * FROM projects ORDER BY id DESC LIMIT 1")->fetch();
   $tasks=$pdo->query("SELECT * FROM activities ORDER BY start_date,id")->fetchAll();
   $def=$pdo->query("SELECT COUNT(*) FROM defects WHERE severity='Critical' AND status<>'Resolved'")->fetchColumn();
   $pending=$pdo->query("SELECT COUNT(*) FROM change_requests WHERE status='Pending'")->fetchColumn();
   $delayed=$pdo->query("SELECT COUNT(*) FROM activities WHERE status='Delayed'")->fetchColumn();
   $spent=(float)$pdo->query("SELECT COALESCE(SUM(actual_cost),0) FROM activities")->fetchColumn();
   $progress=count($tasks)?array_sum(array_map(fn($t)=>(float)$t['progress'],$tasks))/count($tasks):0;
   out(['project'=>$p,'tasks'=>$tasks,'progress'=>round($progress,1),'actual_cost'=>$spent,'critical_defects'=>(int)$def,'pending_changes'=>(int)$pending,'delayed_tasks'=>(int)$delayed]);
 }
 $map=[
  'project'=>['projects',['project_name','client_name','objectives','stakeholders','scope_inclusions','scope_exclusions','approved_budget','baseline_weeks','start_date','deadline','status','quality_plan','closure_notes']],
  'requirements'=>['requirements',['title','description','priority','status','category']],
  'wbs'=>['wbs_items',['wbs_code','deliverable','work_package','parent_id','owner','status']],
  'changes'=>['change_requests',['title','justification','cost_impact','weeks_impact','status','approved_by','applied']],
  'activities'=>['activities',['wbs_id','title','description','assignee_id','assignee_name','start_date','end_date','duration_days','dependency_ids','budgeted_cost','actual_cost','progress','status','is_milestone']],
  'team'=>['team_members',['name','role','email','allocation_percent']],
  'defects'=>['defects',['title','description','severity','module','assigned_to','status','reported_date','resolved_date']],
  'checks'=>['quality_checks',['title','deliverable','result','inspector','inspection_date','notes']],
  'risks'=>['risks',['title','description','likelihood','impact','response_action','owner','status']]
 ];
 if(!isset($map[$resource])) out(['success'=>false,'message'=>'Unknown API resource.'],404);
 [$table,$allowed]=$map[$resource];
 if($method==='GET'){
   $rows=$pdo->query("SELECT * FROM `$table` ORDER BY id DESC")->fetchAll();
   out(['success'=>true,'items'=>$rows]);
 }
 if($method==='POST' || $method==='PUT'){
   $data=body(); $id=isset($data['id'])?(int)$data['id']:null;
   if($resource==='project' && empty($data['project_name'])) out(['success'=>false,'message'=>'Project name is required.'],422);
   if($resource==='requirements' && empty($data['title'])) out(['success'=>false,'message'=>'Requirement title is required.'],422);
   if($resource==='activities' && (numv($data['progress']??0)<0 || numv($data['progress']??0)>100)) out(['success'=>false,'message'=>'Progress must be between 0 and 100.'],422);
   if($resource==='risks' && ((int)($data['likelihood']??1)<1 || (int)($data['likelihood']??1)>5 || (int)($data['impact']??1)<1 || (int)($data['impact']??1)>5)) out(['success'=>false,'message'=>'Risk likelihood and impact must be from 1 to 5.'],422);
   if($resource==='changes' && !in_array($data['status']??'Pending',['Pending','Approved','Rejected'],true)) out(['success'=>false,'message'=>'Invalid change request status.'],422);
   $newId=record($pdo,$table,$data,$allowed,$id); out(['success'=>true,'id'=>$newId,'message'=>'Record saved successfully.']);
 }
 if($method==='DELETE'){
   $id=(int)($_GET['id']??0); if(!$id) out(['success'=>false,'message'=>'A valid record ID is required.'],422);
   $s=$pdo->prepare("DELETE FROM `$table` WHERE id=?");$s->execute([$id]); if(!$s->rowCount()) out(['success'=>false,'message'=>'Record not found.'],404);
   out(['success'=>true,'message'=>'Record deleted.']);
 }
 out(['success'=>false,'message'=>'Method not allowed.'],405);
} catch(Throwable $e){ error_log('HealthPMS API: '.$e->getMessage()); out(['success'=>false,'message'=>$e instanceof InvalidArgumentException||$e instanceof RuntimeException?$e->getMessage():'Server error. Check PHP error log.'],500); }
