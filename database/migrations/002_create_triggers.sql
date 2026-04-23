-- MySQL Triggers for Business Management System
-- Auto-generate codes and maintain data integrity

DELIMITER $$

-- Trigger for auto-generating product codes
DROP TRIGGER IF EXISTS before_product_insert$$
CREATE TRIGGER before_product_insert
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.code IS NULL OR NEW.code = '' THEN
        SET @next_num = (SELECT COALESCE(MAX(CAST(SUBSTRING(code, 4) AS UNSIGNED)), 0) + 1 FROM products WHERE code LIKE 'PRD%');
        SET NEW.code = CONCAT('PRD', LPAD(@next_num, 6, '0'));
    END IF;
END$$

-- Trigger for auto-generating customer codes
DROP TRIGGER IF EXISTS before_customer_insert$$
CREATE TRIGGER before_customer_insert
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    IF NEW.code IS NULL OR NEW.code = '' THEN
        SET @next_num = (SELECT COALESCE(MAX(CAST(SUBSTRING(code, 4) AS UNSIGNED)), 0) + 1 FROM customers WHERE code LIKE 'CUS%');
        SET NEW.code = CONCAT('CUS', LPAD(@next_num, 6, '0'));
    END IF;
END$$

-- Trigger for auto-generating supplier codes
DROP TRIGGER IF EXISTS before_supplier_insert$$
CREATE TRIGGER before_supplier_insert
BEFORE INSERT ON suppliers
FOR EACH ROW
BEGIN
    IF NEW.code IS NULL OR NEW.code = '' THEN
        SET @next_num = (SELECT COALESCE(MAX(CAST(SUBSTRING(code, 4) AS UNSIGNED)), 0) + 1 FROM suppliers WHERE code LIKE 'SUP%');
        SET NEW.code = CONCAT('SUP', LPAD(@next_num, 6, '0'));
    END IF;
END$$

-- Trigger for auto-generating employee codes
DROP TRIGGER IF EXISTS before_employee_insert$$
CREATE TRIGGER before_employee_insert
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF NEW.code IS NULL OR NEW.code = '' THEN
        SET @next_num = (SELECT COALESCE(MAX(CAST(SUBSTRING(code, 4) AS UNSIGNED)), 0) + 1 FROM employees WHERE code LIKE 'EMP%');
        SET NEW.code = CONCAT('EMP', LPAD(@next_num, 6, '0'));
    END IF;
END$$

-- Trigger to update product stock on sale
DROP TRIGGER IF EXISTS after_sale_item_insert$$
CREATE TRIGGER after_sale_item_insert
AFTER INSERT ON sale_items
FOR EACH ROW
BEGIN
    UPDATE products 
    SET current_stock = current_stock - NEW.quantity
    WHERE id = NEW.product_id;
    
    INSERT INTO inventory_movements (id, product_id, movement_type, quantity, reference_type, reference_id, created_at)
    VALUES (UUID(), NEW.product_id, 'out', NEW.quantity, 'sale', NEW.sale_id, NOW());
END$$

-- Trigger to update product stock on purchase
DROP TRIGGER IF EXISTS after_purchase_item_insert$$
CREATE TRIGGER after_purchase_item_insert
AFTER INSERT ON purchase_items
FOR EACH ROW
BEGIN
    UPDATE products 
    SET current_stock = current_stock + NEW.quantity
    WHERE id = NEW.product_id;
    
    INSERT INTO inventory_movements (id, product_id, movement_type, quantity, unit_cost, reference_type, reference_id, created_at)
    VALUES (UUID(), NEW.product_id, 'in', NEW.quantity, NEW.unit_cost, 'purchase', NEW.purchase_id, NOW());
END$$

-- Trigger to revert stock on sale item delete
DROP TRIGGER IF EXISTS after_sale_item_delete$$
CREATE TRIGGER after_sale_item_delete
AFTER DELETE ON sale_items
FOR EACH ROW
BEGIN
    UPDATE products 
    SET current_stock = current_stock + OLD.quantity
    WHERE id = OLD.product_id;
    
    INSERT INTO inventory_movements (id, product_id, movement_type, quantity, reference_type, reference_id, description, created_at)
    VALUES (UUID(), OLD.product_id, 'in', OLD.quantity, 'sale_reversal', OLD.sale_id, 'Sale item deleted', NOW());
END$$

-- Trigger to revert stock on purchase item delete
DROP TRIGGER IF EXISTS after_purchase_item_delete$$
CREATE TRIGGER after_purchase_item_delete
AFTER DELETE ON purchase_items
FOR EACH ROW
BEGIN
    UPDATE products 
    SET current_stock = current_stock - OLD.quantity
    WHERE id = OLD.product_id;
    
    INSERT INTO inventory_movements (id, product_id, movement_type, quantity, reference_type, reference_id, description, created_at)
    VALUES (UUID(), OLD.product_id, 'out', OLD.quantity, 'purchase_reversal', OLD.purchase_id, 'Purchase item deleted', NOW());
END$$

DELIMITER ;
