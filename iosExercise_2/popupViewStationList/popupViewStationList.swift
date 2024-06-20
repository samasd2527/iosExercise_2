//
//  popupViewStationList.swift
//  iosExercise_2
//
//  Created by 莊善傑 on 2024/6/14.
//

import UIKit

class popupViewStationList: UIViewController {
    
    var stationInfos: [StationInfo] = []
    var filteredData: [StationInfo] = []
    var delegate: popupViewStationListDelegate?
    var state: Int?
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var tableView1: UITableView!
    @IBOutlet weak var searchStationTextField: UITextField!
    
    init() {
        super.init(nibName: "popupViewStationList", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView1.delegate = self
        tableView1.dataSource = self
        searchStationTextField.delegate = self
        let nib = UINib(nibName: "CustomTableViewCell", bundle: nil)
        tableView1.register(nib, forCellReuseIdentifier: "CustomCell")
        configView()
        filteredData = stationInfos
        swipeDown()
    }
    
    private func configView() {
        self.view.backgroundColor = .clear
        self.backView.backgroundColor = .black.withAlphaComponent(0.6)
        self.backView.alpha = 0
        self.popupView.alpha = 0
        self.popupView.layer.cornerRadius = 10
    }
    
    func swipeDown(){
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swapDownView(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    func appear(sender: ViewController) {
        sender.present(self, animated: false) {
            self.show()
        }
    }
    
    private func show() {
        UIView.animate(withDuration: 1, delay: 0.1) {
            self.backView.alpha = 1
            self.popupView.alpha = 1
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseOut) {
            self.backView.alpha = 0
            self.popupView.alpha = 0
            self.searchStationTextField.resignFirstResponder()
        } completion: { _ in
            self.dismiss(animated: false)
            self.removeFromParent()
        }
    }

    @IBAction func swapDownView(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == .down {
            hide()
        }
    }
    
    @IBAction func dismissView(_ sender: UITapGestureRecognizer) {
        hide()
    }
}

extension popupViewStationList: UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return filteredData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomTableViewCell
        let station = filteredData[indexPath.row]
        cell.titleLabel.text = "\(station.name)高鐵站"
        cell.subtitleLabel.text = station.addr
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if state == 1 {
            delegate?.didSelectStationWithStartBtn(filteredData[indexPath.row])
        }
        else if state == 2 {
            delegate?.didSelectStationWithEndBtn(filteredData[indexPath.row])
        }
        else{
            delegate?.didSelectStation(filteredData[indexPath.row])
        }
        hide()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchStationTextField.resignFirstResponder()
    }
}

extension popupViewStationList: UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
        filterData(with: updatedText)
        return true
    }
    
    func filterData(with query: String) {
        if query.isEmpty {
            filteredData = stationInfos
        } else {
            filteredData = stationInfos.filter { $0.name.contains(query) || $0.addr.contains(query) }
        }
        tableView1.reloadData()
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        filteredData = stationInfos
        tableView1.reloadData()
        return true
    }
}
