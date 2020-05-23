//
//  ViewController.swift
//  Contacts
//
//  Created by Ahn on 2020/05/23.
//  Copyright © 2020 ozofweird. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
// 1. AppDelegate 객체 참조, 관리 객체 컨텍스트 참조 변수 생성
//    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let appdelegate = UIApplication.shared.delegate as! AppDelegate
    lazy var context: NSManagedObjectContext = {
        return self.appdelegate.persistentContainer.viewContext
    }()
    
// 2-1. 데이터 소스 역할을 할 배열 변수
    lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // 위임
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // TableCell 연결
        let cellNib = UINib(nibName: "TableCell", bundle: nil)
        self.tableView.register(cellNib, forCellReuseIdentifier: "TableCell")
        
        // 셀 높이 디폴트
        self.tableView.estimatedRowHeight = 200
    }
    
    @IBAction func addBtn(_ sender: Any) {
        let alert = UIAlertController(title: "연락처 등록", message: nil, preferredStyle: .alert)
        alert.addTextField() { $0.placeholder = "이름" }
        alert.addTextField() { $0.placeholder = "번호" }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) {(_) in
            guard let nameBtn = alert.textFields?.first?.text, let phoneBtn = alert.textFields?.last?.text else {
                return
            }
            // 값을 저장, 성공이면 테이블 리로드
            if self.save(name: nameBtn, phone: phoneBtn) == true {
                self.tableView.reloadData()
            }
        })
        self.present(alert, animated: false)
    }
    
}

extension ViewController {
    
// 2. CoreData에서 데이터 추출 (모든 데이터)
    func fetch() -> [NSManagedObject] {
        // 요청 객체 생성
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Contacts")
        
        // 6. 정렬 속성 설정
        let sort = NSSortDescriptor(key: "regDate", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        // 데이터 가져오기
        let result = try! self.context.fetch(fetchRequest)
        return result
    }
    
// 3. 데이터 등록
    func save(name: String, phone: String) -> Bool {
        // 관리 객체 생성, 값 설정
        let object = NSEntityDescription.insertNewObject(forEntityName: "Contacts", into: context)
        object.setValue(name, forKey: "name")
        object.setValue(phone, forKey: "phone")
        object.setValue(Date(), forKey: "regDate")
        
        // 영구 저장소에 커밋되고 나면 list 프로퍼티에 추가
        do {
            try self.context.save()
//            self.list.append(object)
            
// 6-1. 추가와 동시에 가장 첫번째 행 설정
            self.list.insert(object, at: 0)
            
            return true
        } catch {
            self.context.rollback()
            return false
        }
    }
    
// 4. 데이터 삭제
    func delete(object: NSManagedObject) -> Bool {
        // 컨텍스트로부터 해당 객체 삭제
        self.context.delete(object)
        
        // 영구 저장소에 커밋
        do {
            try self.context.save()
            return true
        } catch {
            self.context.rollback()
            return false
        }
    }
    
// 5. 데이터 수정
    func edit(object: NSManagedObject, name: String, phone: String) -> Bool {
        // 관리 객체의 값을 수정
        object.setValue(name, forKey: "name")
        object.setValue(phone, forKey: "phone")
        object.setValue(Date(), forKey: "regDate")
        
        // 영구 저장소에 커밋
        do {
            try self.context.save()
            
            // 6-2. list 배열 갱신
            self.list = self.fetch()
            
            return true
        } catch {
            self.context.rollback()
            return false
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.list.count
    }
    
// 2-2. 데이터 로드
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 데이터 가져오기
        let record = self.list[indexPath.row]
        let recordName = record.value(forKey: "name") as? String
        let recordPhone = record.value(forKey: "phone") as? String
        
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as? TableCell else {
            return UITableViewCell()
        }
        
        cell.nameLabel?.text = recordName
        cell.phoneLabel?.text = recordPhone
        
        return cell
    }
    
// 4-1. 테이블 데이터 삭제
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let object = self.list[indexPath.row]
            
            if self.delete(object: object) {
                // 코어 데이터에서 삭제되면 배열 목록과 테이블 뷰의 행도 삭제
                self.list.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
// 5-1. 테이블 데이터 수정
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 선택된 행에 해당하는 데이터 가져옴
        let object = self.list[indexPath.row]
        let objectName = object.value(forKey: "name") as? String
        let objectPhone = object.value(forKey: "phone") as? String
             
        let alert = UIAlertController(title: "연락처 수정", message: nil, preferredStyle: .alert)
        alert.addTextField() { $0.text = objectName }
        alert.addTextField() { $0.text = objectPhone }
             
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { (_) in
            guard let nameBtn = alert.textFields?.first?.text, let phoneBtn = alert.textFields?.last?.text else {
                return
            }
                 
            // 값을 수정하는 메서드 호출, 성공시 테이블 뷰 리로드
            if self.edit(object: object, name: nameBtn, phone: phoneBtn) == true {
                self.tableView.reloadData()
                
            }
        })
        self.present(alert, animated: false)
        
    }

    
}
