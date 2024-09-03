/**
 * ProductController
 *
 * @description Handles the logic for the Product Console.
 */
public with sharing class ProductController {
    static Integer PAGE_SIZE = 9;

    /**
     * @description Contains the possible filters for the Product Console.
     */
    public class Filters {
        /**
         * @description Contains the search key for the Product Console.
         */
        @AuraEnabled
        public String searchKey { get; set; }
        /**
         * @description Contains the maximum price for the Product Console.
         */
        @AuraEnabled
        public Decimal maxPrice { get; set; }
        /**
         * @description Contains the categories for the Product Console.
         */
        @AuraEnabled
        public String[] categories { get; set; }
        /**
         * @description Contains the materials for the Product Console.
         */
        @AuraEnabled
        public String[] materials { get; set; }
        /**
         * @description Contains the levels for the Product Console.
         */
        @AuraEnabled
        public String[] levels { get; set; }
    }

    /**
     * @description Returns a list of products based on the filters.
     * @param filters The filters for the Product Console.
     * @param pageNumber The page number for the Product Console.
     * @return A list of products.
     */
    @AuraEnabled(Cacheable=true scope='global')
    public static PagedResult getProducts(Filters filters, Integer pageNumber) {
        Decimal maxPrice;
        String key, whereClause = '';
        String[] categories, materials, levels, criteria = new List<String>{};
        if (filters != null) {
            maxPrice = filters.maxPrice;
            materials = filters.materials;
            levels = filters.levels;
            if (!String.isEmpty(filters.searchKey)) {
                key = '%' + filters.searchKey + '%';
                criteria.add('Name LIKE :key');
            }
            if (filters.maxPrice >= 0) {
                maxPrice = filters.maxPrice;
                criteria.add('MSRP__c <= :maxPrice');
            }
            if (filters.categories != null) {
                categories = filters.categories;
                criteria.add('Category__c IN :categories');
            }
            if (filters.levels != null) {
                levels = filters.levels;
                criteria.add('Level__c IN :levels');
            }
            if (filters.materials != null) {
                materials = filters.materials;
                // TODO Re-enable the materials filter before going live.
                //criteria.add('Material__c IN :materials');
            }
            if (criteria.size() > 0) {
                whereClause = 'WHERE ' + String.join(criteria, ' AND ');
            }
        }
        Integer pageSize = ProductController.PAGE_SIZE;
        Integer offset = (pageNumber - 1) * pageSize;
        PagedResult result = new PagedResult();
        result.pageSize = pageSize;
        result.pageNumber = pageNumber;
        result.totalItemCount = Database.countQuery(
            'SELECT count() FROM Product__c ' + whereClause
        );
        for (Integer i = 0; i < 1; i++) {
            result.records = Database.query(
                'SELECT Id, Name, MSRP__c, Description__c, Category__c, Level__c, Picture_URL__c, Material__c FROM Product__c ' +
                    whereClause +
                    ' WITH USER_MODE' +
                    ' ORDER BY Name LIMIT :pageSize OFFSET :offset'
            );
        }
        return result;
    }

    @AuraEnabled(Cacheable=true scope='global')
    public static Product__c[] getSimilarProducts(Id productId, Id familyId) {
        return [
            SELECT
                Id,
                Name,
                MSRP__c,
                Description__c,
                Category__c,
                Level__c,
                Picture_URL__c,
                Material__c
            FROM Product__c
            WHERE Product_Family__c = :familyId AND Id != :productId
            WITH USER_MODE
        ];
    }

    /**
     * @description Returns a list of editable fields for the Product Console.
     * @param sObjectName The SObject name.
     * @return A list of editable fields.
     */
    @AuraEnabled(Cacheable=true scope='global')
    public static List<String> getEditableFields(String sObjectName) {
        // Get the describe information for the provided SObject name
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);        
        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();

        // Get all fields on the specified SObject
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();

        // Iterate over each field to check FLS
        List<String> editableFields = new List<String>();
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
            if (fieldDescribe.isUpdateable()) {
                editableFields.add(fieldName);
            }
        }
        return editableFields;
    }
}
